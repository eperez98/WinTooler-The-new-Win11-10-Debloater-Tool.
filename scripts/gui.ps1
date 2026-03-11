# scripts/gui.ps1
# WinToolerV1 GUI - Full WPF interface
# Features: Dark/Light mode, macOS-style icons, Tweak templates,
#           App Updates tab, Uninstall tab, Async SFC/DISM

function Start-WinToolerGUI {

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Windows.Forms

    # ----------------------------------------------------------------
    #  AERO / DWM GLASS  — extend frame into client area for frosted look
    # ----------------------------------------------------------------
    try {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class AeroGlass {
    [StructLayout(LayoutKind.Sequential)]
    public struct MARGINS { public int Left, Right, Top, Bottom; }
    [DllImport("dwmapi.dll")]
    public static extern int DwmExtendFrameIntoClientArea(IntPtr hwnd, ref MARGINS m);
    [DllImport("dwmapi.dll")]
    public static extern int DwmIsCompositionEnabled(out bool enabled);
    [DllImport("user32.dll")]
    public static extern bool SetLayeredWindowAttributes(IntPtr hwnd, uint crKey, byte bAlpha, uint dwFlags);
}
'@ -ErrorAction SilentlyContinue
    } catch {}

    $script:IsDark = $false

    # ----------------------------------------------------------------
    #  THEME HELPERS - called at build time and on toggle
    # ----------------------------------------------------------------
    $script:T = @{}  # theme palette - rebuilt by Set-Theme

    function script:Set-Theme {
        param([bool]$dark)
        # Aero-glass blue palette (v0.6.1)
        $script:T = @{
            WinBG        = "#D8EAF5"; SidebarBG     = "#CCE0F0"; SidebarBorder = "#B0CCE4"
            Surface1     = "#E4EFF8"; Surface2      = "#EEF6FF"; Surface3      = "#D8EAF5"
            Border1      = "#B8D0E8"; Border2       = "#A0BCD8"
            Text1        = "#0A1A2A"; Text2         = "#1A2A3A"; Text3         = "#3A5570"; Text4 = "#6A8AA8"
            Accent       = "#0067C0"; AccentH       = "#0078D4"; AccentP       = "#005AA8"
            NavBtnFG     = "#1A3A5C"; NavActBG      = "#C4D8F0"; NavActFG      = "#0055B0"
            CardBG       = "#EEF6FF"; CardBorder    = "#B8D0E8"
            InputBG      = "#F4FAFF"; StatusBG      = "#CCE0F0"; StatusBorder  = "#A0BCD8"
            Green        = "#107C10"; Red           = "#C42B1C"; Yellow        = "#B06B00"; Orange = "#D83B01"
            # Nav icon badge dark-tint tokens (bg + icon fg)
            BadgeInstallBG      = "#1A3A5C"; BadgeInstallFG      = "#C8E4FF"
            BadgeUninstallBG    = "#3A1A1A"; BadgeUninstallFG    = "#FFCCCC"
            BadgeUpdatesBG      = "#1A3A1A"; BadgeUpdatesFG      = "#AAFFCC"
            BadgeTweaksBG       = "#2A1A4A"; BadgeTweaksFG       = "#D8C8FF"
            BadgeServicesBG     = "#0A2A3A"; BadgeServicesFG     = "#AAE4FF"
            BadgeRepairBG       = "#3A2A0A"; BadgeRepairFG       = "#FFE0A0"
            BadgeWinUpdBG       = "#0A2A1A"; BadgeWinUpdFG       = "#AAFFD8"
            BadgeAboutBG        = "#2A0A3A"; BadgeAboutFG        = "#E0C8FF"
        }
    }

    function script:Brush { param([string]$hex)
        New-Object Windows.Media.SolidColorBrush([Windows.Media.ColorConverter]::ConvertFromString($hex))
    }
    function script:BrushA { param([string]$hex, [byte]$a)
        $c = [Windows.Media.ColorConverter]::ConvertFromString($hex)
        New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb($a, $c.R, $c.G, $c.B))
    }

    & script:Set-Theme $false

    # ----------------------------------------------------------------
    #  LANGUAGE STRINGS
    # ----------------------------------------------------------------
    # Pin language immediately so nothing can reset it later in the session
    $lang = if ($global:UILanguage -eq "ES") { "ES" } else { "EN" }
    $global:UILanguage = $lang
    $script:lang = $lang   # script-scoped so Apply-Language and toggle closures can read/write it

    $S = @{}   # UI strings - keyed by control/label name

    if ($lang -eq "ES") {
        $S = @{
            # Nav labels
            NavApps       = "Aplicaciones"
            NavInstall    = "Instalar Apps";    NavUninstall   = "Desinstalar"
            NavTweaks      = "Ajustes"
            NavServices   = "Servicios";        NavRepair      = "Reparar"
            NavUpdates    = "Windows Update";   NavAbout = "Acerca de"
            # Page titles
            TitleApps       = "Aplicaciones"
            SubApps         = "Instala o desinstala apps via winget"
            ModeLblInstall   = "Instalar"
            ModeLblUninstall = "Desinstalar"
            ModeLblUpdateAll = "Actualizar Todo"
            TitleInstall    = "Instalar Aplicaciones"
            SubInstall      = "Selecciona las apps a instalar via winget"
            TitleUninstall  = "Desinstalar Aplicaciones"
            SubUninstall    = "Elimina apps administradas por winget"
            TitleTweaks     = "Ajustes del Sistema"
            SubTweaks       = "Optimizacion de rendimiento, privacidad e interfaz"
            TitleServices   = "Servicios de Windows"
            SubServices     = "Gestiona servicios en segundo plano"
            TitleRepair     = "Reparacion y Mantenimiento"
            SubRepair       = "Diagnostica y repara problemas comunes de Windows"
            TitleUpdates    = "Windows Update"
            SubUpdates      = "Busca, instala, pausa o reanuda actualizaciones"
            TitleAbout      = "Acerca de WinToolerV1"
            SubAbout        = "Informacion de version y creditos"
            # Buttons
            BtnSelectAll     = "Selec. Todo";   BtnDeselectAll  = "Ninguno"
            BtnInstall       = "Instalar Seleccionados"
            BtnInstallCancel = "Cancelar"
            BtnRefreshUn     = "Actualizar Lista"
            BtnUninstall     = "Desinstalar Seleccionados"
            BtnCheckAll      = "Selec. Todo";   BtnUncheckAll   = "Ninguno"
            BtnApplyTweaks   = "Aplicar Ajustes Seleccionados"
            BtnUndoTweaks    = "Deshacer Seleccionados"
            BtnSvcDisable    = "Deshabilitar Selec."
            BtnSvcManual     = "Poner Manual"
            BtnSvcEnable     = "Reactivar"
            BtnRunUpdates    = "Buscar e Instalar"
            BtnPauseUpdates  = "Pausar 7 Dias"
            BtnResumeUpdates = "Reanudar Updates"
            BtnOpenLog       = "Abrir Archivo de Log"
            TplNone          = "Ninguno";        TplStandard = "Estandar"
            TplMinimal       = "Minimo";         TplHeavy    = "Completo"
            LangToggleLabel  = "Idioma"
            DiskCleanTitle   = "Limpieza de Disco"
            DiskCleanMsg     = "Ejecutando limpieza de disco en segundo plano..."
            DiskCleanDone    = "Limpieza de disco finalizada."
            TweaksDone       = "Listo! Aplicados"
            TweaksOf         = "de"
            TweaksDiskClean  = "tweaks. Iniciando limpieza de disco..."
            SearchPlaceholder = "Buscar...";     Ready = "Listo"
            StatusReady      = "Listo"
            AboutVersion     = "Version";        AboutLicense = "Licencia"
            AboutInspired    = "Inspirado en"
            AboutLog         = "Archivo de log"
        }
    } else {
        $S = @{
            NavApps       = "Applications"
            NavInstall    = "Install Apps";     NavUninstall   = "Uninstall"
            NavAppUpdates = "App Updates";      NavTweaks      = "Tweaks"
            NavServices   = "Services";         NavRepair      = "Repair"
            NavUpdates    = "Windows Update";   NavAbout       = "About"
            TitleApps       = "Applications"
            SubApps         = "Install, uninstall or update apps via winget"
            ModeLblInstall   = "Install"
            ModeLblUninstall = "Uninstall"
            ModeLblUpdateAll = "Update All Apps"
            TitleInstall    = "Install Applications"
            SubInstall      = "Select apps to install via winget"
            TitleUninstall  = "Uninstall Applications"
            SubUninstall    = "Remove winget-managed apps from your system"
            TitleAppUpdates = "App Updates"
            SubAppUpdates   = "Apps with updates available - scanned at startup"
            TitleTweaks     = "System Tweaks"
            SubTweaks       = "Apply performance, privacy and UI optimisations"
            TitleServices   = "Windows Services"
            SubServices     = "Manage and disable unnecessary background services"
            TitleRepair     = "Repair and Maintenance"
            SubRepair       = "Diagnose and fix common Windows issues"
            TitleUpdates    = "Windows Updates"
            SubUpdates      = "Check, install, pause or resume Windows updates"
            TitleAbout      = "About WinToolerV1"
            SubAbout        = "Version information and credits"
            BtnSelectAll     = "Select All";    BtnDeselectAll  = "None"
            BtnInstall       = "Install Selected"
            BtnInstallCancel = "Cancel"
            BtnRefreshUn     = "Refresh List"
            BtnUninstall     = "Uninstall Selected"
            BtnCheckAll      = "Select All";    BtnUncheckAll   = "None"
            BtnApplyTweaks   = "Apply Selected Tweaks"
            BtnUndoTweaks    = "Undo Selected"
            BtnSvcDisable    = "Disable Selected"
            BtnSvcManual     = "Set Manual"
            BtnSvcEnable     = "Re-Enable"
            BtnRunUpdates    = "Check and Install"
            BtnPauseUpdates  = "Pause 7 Days"
            BtnResumeUpdates = "Resume Updates"
            BtnOpenLog       = "Open Log File"
            TplNone          = "None";           TplStandard = "Standard"
            TplMinimal       = "Minimal";        TplHeavy    = "Heavy"
            LangToggleLabel  = "Language"
            DiskCleanTitle   = "Disk Cleanup"
            DiskCleanMsg     = "Running disk cleanup in the background..."
            DiskCleanDone    = "Disk cleanup finished."
            TweaksDone       = "Done! Applied"
            TweaksOf         = "of"
            TweaksDiskClean  = "tweaks. Running disk cleanup..."
            SearchPlaceholder = "Search..."
            StatusReady      = "Ready"
            AboutVersion     = "Version";        AboutLicense = "License"
            AboutInspired    = "Inspired by"
            AboutLog         = "Log file"
        }
    }
    $global:UIStrings = $S

    # ----------------------------------------------------------------
    #  XAML
    # ----------------------------------------------------------------
    [xml]$XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="WinToolerV1 v0.6.1 BETA Build 4.100"
    Width="1180" Height="780"
    MinWidth="980" MinHeight="640"
    WindowStartupLocation="CenterScreen"
    Background="#D8EAF5"
    FontFamily="Segoe UI Variable Text, Segoe UI, Sans-Serif"
    FontSize="13"
    ResizeMode="CanResize">

  <Window.Resources>
    <!-- Fluent Design color tokens -->
    <SolidColorBrush x:Key="Accent"      Color="#0067C0"/>
    <SolidColorBrush x:Key="AccentHover" Color="#0078D4"/>
    <SolidColorBrush x:Key="AccentPress" Color="#005AA8"/>
    <SolidColorBrush x:Key="Green"       Color="#107C10"/>
    <SolidColorBrush x:Key="Red"         Color="#C42B1C"/>
    <SolidColorBrush x:Key="Yellow"      Color="#B06B00"/>
    <SolidColorBrush x:Key="Orange"      Color="#D83B01"/>

    <!-- Drop shadow effect for cards -->
    <DropShadowEffect x:Key="CardShadow" BlurRadius="12" ShadowDepth="1"
                      Direction="270" Color="#000000" Opacity="0.07"/>
    <DropShadowEffect x:Key="CardShadowMd" BlurRadius="18" ShadowDepth="2"
                      Direction="270" Color="#000000" Opacity="0.09"/>

    <!-- Primary accent button -->
    <Style x:Key="BtnAccent" TargetType="Button">
      <Setter Property="Background"      Value="#0067C0"/>
      <Setter Property="Foreground"      Value="White"/>
      <Setter Property="FontWeight"      Value="SemiBold"/>
      <Setter Property="FontSize"        Value="13"/>
      <Setter Property="Padding"         Value="18,8"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor"          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}"
                    CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#0078D4"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#005AA8"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter TargetName="bd" Property="Background" Value="#E8E8E8"/>
                <Setter Property="Foreground" Value="#AAAAAA"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Ghost / outline button -->
    <Style x:Key="BtnGhost" TargetType="Button">
      <Setter Property="Background"      Value="#FFFFFF"/>
      <Setter Property="Foreground"      Value="#323130"/>
      <Setter Property="FontSize"        Value="13"/>
      <Setter Property="Padding"         Value="14,7"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="BorderBrush"     Value="#D1D1D1"/>
      <Setter Property="Cursor"          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#F0F6FF"/>
                <Setter TargetName="bd" Property="BorderBrush" Value="#0067C0"/>
                <Setter Property="Foreground" Value="#0067C0"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#E3EEFA"/>
              </Trigger>
              <Trigger Property="IsEnabled" Value="False">
                <Setter Property="Foreground" Value="#AAAAAA"/>
                <Setter TargetName="bd" Property="BorderBrush" Value="#E0E0E0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="BtnDanger" TargetType="Button" BasedOn="{StaticResource BtnGhost}">
      <Setter Property="BorderBrush" Value="#F8BBBB"/>
      <Setter Property="Foreground"  Value="#C42B1C"/>
      <Setter Property="Background"  Value="#FFF6F6"/>
    </Style>

    <Style x:Key="BtnSuccess" TargetType="Button" BasedOn="{StaticResource BtnGhost}">
      <Setter Property="BorderBrush" Value="#B3DEB3"/>
      <Setter Property="Foreground"  Value="#107C10"/>
      <Setter Property="Background"  Value="#F3FBF3"/>
    </Style>

    <!-- Fluent nav button - with left accent bar via Grid trick -->
    <Style x:Key="NavBtn" TargetType="Button">
      <Setter Property="Background"                  Value="Transparent"/>
      <Setter Property="Foreground"                  Value="#5A5A5A"/>
      <Setter Property="FontSize"                    Value="13"/>
      <Setter Property="Padding"                     Value="10,10"/>
      <Setter Property="BorderThickness"             Value="0"/>
      <Setter Property="HorizontalContentAlignment"  Value="Left"/>
      <Setter Property="Margin"                      Value="8,1,8,1"/>
      <Setter Property="Cursor"                      Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Grid>
              <!-- Left accent bar (hidden when inactive) -->
              <Border x:Name="accent" Width="3" HorizontalAlignment="Left"
                      Background="#0067C0" CornerRadius="2" Visibility="Collapsed"
                      Margin="-8,4,-8,4"/>
              <Border x:Name="bd" Background="{TemplateBinding Background}"
                      CornerRadius="6" Padding="{TemplateBinding Padding}">
                <ContentPresenter HorizontalAlignment="Left" VerticalAlignment="Center"/>
              </Border>
            </Grid>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd"     Property="Background" Value="#EEF3FC"/>
                <Setter Property="Foreground" Value="#0067C0"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#E3EEFA"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="NavBtnActive" TargetType="Button" BasedOn="{StaticResource NavBtn}">
      <Setter Property="Background" Value="#EEF3FC"/>
      <Setter Property="Foreground" Value="#0067C0"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
    </Style>

    <!-- Fluent search / input box -->
    <Style x:Key="SearchBox" TargetType="TextBox">
      <Setter Property="Background"       Value="#FFFFFF"/>
      <Setter Property="Foreground"       Value="#323130"/>
      <Setter Property="CaretBrush"       Value="#323130"/>
      <Setter Property="BorderBrush"      Value="#D1D1D1"/>
      <Setter Property="BorderThickness"  Value="1"/>
      <Setter Property="Padding"          Value="10,7"/>
      <Setter Property="FontSize"         Value="13"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="TextBox">
            <Border x:Name="bd" Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ScrollViewer x:Name="PART_ContentHost"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsFocused" Value="True">
                <Setter TargetName="bd" Property="BorderBrush" Value="#0067C0"/>
                <Setter TargetName="bd" Property="BorderThickness" Value="1.5"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="BorderBrush" Value="#888888"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Slim scrollbar -->
    <Style x:Key="ScrollBarThumb" TargetType="Thumb">
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Thumb">
            <Border Background="#C8C8C8" CornerRadius="3" Margin="1"/>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="ScrollBar">
      <Setter Property="Width"      Value="5"/>
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="ScrollBar">
            <Track x:Name="PART_Track" IsDirectionReversed="True">
              <Track.Thumb>
                <Thumb Style="{StaticResource ScrollBarThumb}" Margin="0,2"/>
              </Track.Thumb>
            </Track>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Fluent checkbox -->
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="#323130"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="CheckBox">
            <StackPanel Orientation="Horizontal">
              <Border x:Name="box" Width="18" Height="18" CornerRadius="4"
                      Background="#FFFFFF" BorderBrush="#AAAAAA" BorderThickness="1.5"
                      VerticalAlignment="Center">
                <TextBlock x:Name="chk" Text="&#x2714;" FontSize="10"
                           FontWeight="Bold" Foreground="White"
                           HorizontalAlignment="Center" VerticalAlignment="Center"
                           Visibility="Collapsed"/>
              </Border>
              <ContentPresenter Margin="8,0,0,0" VerticalAlignment="Center"/>
            </StackPanel>
            <ControlTemplate.Triggers>
              <Trigger Property="IsChecked" Value="True">
                <Setter TargetName="box" Property="Background"  Value="#0067C0"/>
                <Setter TargetName="box" Property="BorderBrush" Value="#0067C0"/>
                <Setter TargetName="chk" Property="Visibility"  Value="Visible"/>
              </Trigger>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="box" Property="BorderBrush" Value="#0067C0"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <!-- Fluent card style for ComboBox -->
    <Style TargetType="ComboBox">
      <Setter Property="Background"      Value="#FFFFFF"/>
      <Setter Property="Foreground"      Value="#323130"/>
      <Setter Property="BorderBrush"     Value="#D1D1D1"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding"         Value="10,6"/>
      <Setter Property="Height"          Value="34"/>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="*"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <Grid Grid.Row="0">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="210"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <!-- LEFT SIDEBAR -->
      <Border x:Name="Sidebar" Grid.Column="0" Background="#FFFFFF"
              BorderBrush="#E0E0E0" BorderThickness="0,0,1,0">
        <Grid>
          <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
          </Grid.RowDefinitions>

          <!-- Logo -->
          <StackPanel Grid.Row="0" Margin="16,20,16,16">
            <Grid Margin="0,0,0,12">
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
              </Grid.ColumnDefinitions>
              <!-- App icon -->
              <Border Grid.Column="0" Width="44" Height="44" CornerRadius="12"
                      Background="Transparent" Margin="0,0,0,0">
                <Image x:Name="SidebarIcon" Width="44" Height="44"
                       RenderOptions.BitmapScalingMode="HighQuality"
                       Stretch="UniformToFill"/>
              </Border>
            </Grid>
            <TextBlock x:Name="SidebarTitle" Text="WinTooler" FontSize="16" FontWeight="Bold" Foreground="#1A1A1A"/>
            <TextBlock x:Name="SidebarSub" Text="V1  by Eperez98" FontSize="11" Foreground="#777777" Margin="0,2,0,0"/>
          </StackPanel>

          <!-- Nav items -->
          <StackPanel Grid.Row="1" Margin="0,0,0,0">

            <TextBlock Text="APPS" FontSize="10" FontWeight="SemiBold"
                       Foreground="#999999" Margin="20,12,0,5"/>

            <Button x:Name="NavApps" Style="{StaticResource NavBtnActive}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#1A3A5C" Margin="0,0,8,0">
                  <TextBlock Text="&#x2637;" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#C8E4FF"/>
                </Border>
                <TextBlock Text="Applications"/>
              </StackPanel>
            </Button>

            <TextBlock Text="SYSTEM" FontSize="10" FontWeight="SemiBold"
                       Foreground="#999999" Margin="20,10,0,5"/>

            <Button x:Name="NavTweaks" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#2A1A4A" Margin="0,0,8,0">
                  <TextBlock Text="&#x2699;" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#D8C8FF"/>
                </Border>
                <TextBlock Text="Tweaks"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavServices" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#0A2A3A" Margin="0,0,8,0">
                  <TextBlock Text="&#x25B6;" FontSize="10" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#AAE4FF"/>
                </Border>
                <TextBlock Text="Services"/>
              </StackPanel>
            </Button>

            <TextBlock Text="TOOLS" FontSize="10" FontWeight="SemiBold"
                       Foreground="#999999" Margin="20,10,0,5"/>

            <Button x:Name="NavRepair" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#3A2A0A" Margin="0,0,8,0">
                  <TextBlock Text="&#x1F527;" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#FFE0A0"/>
                </Border>
                <TextBlock Text="Repair"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavUpdates" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#0A2A1A" Margin="0,0,8,0">
                  <TextBlock Text="&#x21BA;" FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#AAFFD8"/>
                </Border>
                <TextBlock Text="Windows Update"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavAbout" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#2A0A3A" Margin="0,0,8,0">
                  <TextBlock Text="&#x2139;" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#E0C8FF"/>
                </Border>
                <TextBlock Text="About"/>
              </StackPanel>
            </Button>

          </StackPanel>

          <!-- Winget + OS footer -->
          <Border x:Name="SidebarFooter" Grid.Row="2" Margin="8,0,8,12" Padding="12,10"
                  Background="#F8F9FA" CornerRadius="8"
                  BorderBrush="#EEEEEE" BorderThickness="1"
                  Effect="{StaticResource CardShadow}">
            <StackPanel>
              <!-- Language toggle -->
              <StackPanel Orientation="Horizontal" Margin="0,0,0,8" HorizontalAlignment="Center">
                <TextBlock x:Name="LangLabel" Text="Language" FontSize="10" FontWeight="SemiBold"
                           Foreground="#777777" VerticalAlignment="Center" Margin="0,0,8,0"/>
                <Border CornerRadius="6" BorderBrush="#B8D0E8" BorderThickness="1" ClipToBounds="True">
                  <StackPanel Orientation="Horizontal">
                    <Button x:Name="BtnLangEN" Content="EN"
                            FontSize="11" FontWeight="SemiBold"
                            Width="34" Height="22" BorderThickness="0"
                            Background="#0067C0" Foreground="White"
                            Cursor="Hand">
                      <Button.Template>
                        <ControlTemplate TargetType="Button">
                          <Border x:Name="bdEN" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                          </Border>
                          <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                              <Setter TargetName="bdEN" Property="Opacity" Value="0.85"/>
                            </Trigger>
                          </ControlTemplate.Triggers>
                        </ControlTemplate>
                      </Button.Template>
                    </Button>
                    <Button x:Name="BtnLangES" Content="ES"
                            FontSize="11" FontWeight="SemiBold"
                            Width="34" Height="22" BorderThickness="0"
                            Background="Transparent" Foreground="#3A5570"
                            Cursor="Hand">
                      <Button.Template>
                        <ControlTemplate TargetType="Button">
                          <Border x:Name="bdES" Background="{TemplateBinding Background}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                          </Border>
                          <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                              <Setter TargetName="bdES" Property="Opacity" Value="0.75"/>
                            </Trigger>
                          </ControlTemplate.Triggers>
                        </ControlTemplate>
                      </Button.Template>
                    </Button>
                  </StackPanel>
                </Border>
              </StackPanel>
              <!-- Winget status -->
              <StackPanel Orientation="Horizontal" Margin="0,0,0,3">
                <Ellipse x:Name="WingetDot" Width="7" Height="7"
                         Fill="#FFB900" VerticalAlignment="Center" Margin="0,0,7,0"/>
                <TextBlock x:Name="WingetLabel" Text="winget" FontSize="11" FontWeight="SemiBold" Foreground="#AAAAAA"/>
              </StackPanel>
              <TextBlock x:Name="WingetStatus" Text="Checking..."
                         FontSize="10" Foreground="#777777" TextWrapping="Wrap"/>
              <TextBlock x:Name="OsBadge" FontSize="10" Foreground="#888888"
                         Margin="0,4,0,0" TextWrapping="Wrap"/>
            </StackPanel>
          </Border>
        </Grid>
      </Border>

      <!-- RIGHT CONTENT -->
      <Grid Grid.Column="1">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Page header -->
        <Border x:Name="PageHeader" Grid.Row="0" Background="#FFFFFF"
                BorderBrush="#EEEEEE" BorderThickness="0,0,0,1"
                Padding="28,18">
          <Grid>
            <StackPanel>
              <TextBlock x:Name="PageTitle"    Text="Install Applications"
                         FontSize="20" FontWeight="SemiBold" Foreground="#1A1A1A"/>
              <TextBlock x:Name="PageSubtitle" Text="Select apps to install via winget"
                         FontSize="12" Foreground="#777777" Margin="0,3,0,0"/>
            </StackPanel>
          </Grid>
        </Border>

        <!-- Page switcher -->
        <Grid Grid.Row="1">

          <!-- PAGE: APPS (unified Install / Uninstall / Updates) -->
          <Grid x:Name="PageApps" Visibility="Visible">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="190"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- ── Left: Category sidebar ── -->
            <Border x:Name="CatSidebar" Grid.Column="0" Background="#F7F7F7"
                    BorderBrush="#E0E0E0" BorderThickness="0,0,1,0">
              <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="CatPanel" Margin="8,12"/>
              </ScrollViewer>
            </Border>

            <!-- ── Right: mode bar + content panels ── -->
            <Grid Grid.Column="1">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/><!-- mode segmented bar -->
                <RowDefinition Height="Auto"/><!-- toolbar (search / action buttons) -->
                <RowDefinition Height="*"/>  <!-- scrolling content -->
                <RowDefinition Height="Auto"/><!-- bottom action bar -->
              </Grid.RowDefinitions>

              <!-- ── Mode segmented control bar ── -->
              <Border x:Name="AppsModeBar" Grid.Row="0" Padding="14,9,14,9"
                      Background="#F0F4F8" BorderBrush="#DDE4EC" BorderThickness="0,0,0,1">
                <StackPanel Orientation="Horizontal">
                  <!-- Install mode pill -->
                  <Border x:Name="ModePillInstall" CornerRadius="8" Padding="16,6"
                          Background="#0067C0" Margin="0,0,4,0" Cursor="Hand">
                    <Border.InputBindings>
                      <MouseBinding MouseAction="LeftClick" Command="{x:Null}"/>
                    </Border.InputBindings>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#x2B07;" FontSize="11" Foreground="#FFFFFF"
                                 VerticalAlignment="Center" Margin="0,0,6,0"/>
                      <TextBlock x:Name="ModeLblInstall" Text="Install"
                                 FontSize="12" FontWeight="SemiBold"
                                 Foreground="#FFFFFF" VerticalAlignment="Center"/>
                    </StackPanel>
                  </Border>
                  <!-- Uninstall mode pill -->
                  <Border x:Name="ModePillUninstall" CornerRadius="8" Padding="16,6"
                          Background="Transparent" Margin="0,0,4,0" Cursor="Hand">
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#x2715;" FontSize="11" Foreground="#5A6A7A"
                                 VerticalAlignment="Center" Margin="0,0,6,0"/>
                      <TextBlock x:Name="ModeLblUninstall" Text="Uninstall"
                                 FontSize="12" FontWeight="SemiBold"
                                 Foreground="#5A6A7A" VerticalAlignment="Center"/>
                    </StackPanel>
                  </Border>
                  <!-- Separator -->
                  <Border Width="1" Background="#DDE4EC" Margin="8,4,8,4" VerticalAlignment="Stretch"/>
                  <!-- Update All button — opens external PowerShell window -->
                  <Border x:Name="BtnUpdateAllApps" CornerRadius="8" Padding="14,6"
                          Background="Transparent" Margin="0,0,0,0" Cursor="Hand"
                          ToolTip="Run: winget upgrade --all --accept-source-agreements --accept-package-agreements -h  (opens external window)">
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#x2B06;" FontSize="11" Foreground="#107C10"
                                 VerticalAlignment="Center" Margin="0,0,6,0"/>
                      <TextBlock x:Name="ModeLblUpdateAll" Text="Update All Apps"
                                 FontSize="12" FontWeight="SemiBold"
                                 Foreground="#107C10" VerticalAlignment="Center"/>
                    </StackPanel>
                  </Border>
                </StackPanel>
              </Border>

              <!-- ── Toolbar: search + selection buttons (shared) ── -->
              <Border x:Name="InstallToolbar" Grid.Row="1" Padding="14,10" Background="#FFFFFF"
                      BorderBrush="#E8E8E8" BorderThickness="0,0,0,1">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                  </Grid.ColumnDefinitions>
                  <!-- Search box (shared across all modes) -->
                  <TextBox x:Name="InstallSearch" Grid.Column="0"
                           Style="{StaticResource SearchBox}"
                           Text="" Margin="0,0,10,0"/>
                  <!-- Install-mode controls -->
                  <Button x:Name="BtnSelectAll"   Grid.Column="1" Content="Select All"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0"/>
                  <Button x:Name="BtnDeselectAll" Grid.Column="2" Content="None"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0"/>
                  <Border x:Name="SelCountBadge" Grid.Column="3" Background="#F0F0F0" CornerRadius="8"
                          Padding="10,0" VerticalAlignment="Stretch" Margin="0,0,6,0">
                    <TextBlock x:Name="SelCountTxt" Text="0 selected"
                               FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
                  </Border>
                  <!-- Uninstall-mode refresh -->
                  <Button x:Name="BtnRefreshUninstall" Grid.Column="4"
                          Content="Refresh List" Style="{StaticResource BtnGhost}"
                          Visibility="Collapsed" Margin="0,0,6,0"/>
                  <!-- Uninstall count / Updates status text -->
                  <TextBlock x:Name="UninstallCount" Grid.Column="5"
                             FontSize="12" Foreground="#777777" VerticalAlignment="Center"
                             Margin="4,0,0,0"/>
                </Grid>
              </Border>

              <!-- ── Content area: 3 panels stacked, only one visible at a time ── -->
              <Grid Grid.Row="2">

                <!-- INSTALL panel -->
                <ScrollViewer x:Name="InstallScroll" VerticalScrollBarVisibility="Auto"
                              HorizontalScrollBarVisibility="Disabled" Visibility="Visible">
                  <StackPanel x:Name="AppPanel" Margin="16,12,12,12"/>
                </ScrollViewer>

                <!-- UNINSTALL panel -->
                <ScrollViewer x:Name="UninstallScroll" VerticalScrollBarVisibility="Auto"
                              Visibility="Collapsed">
                  <StackPanel x:Name="UninstallPanel" Margin="16,12,12,12"/>
                </ScrollViewer>

              </Grid>

              <!-- ── Bottom action bar: mode-specific buttons ── -->
              <Border x:Name="InstallBottomBar" Grid.Row="3" Background="#F5F5F5"
                      BorderBrush="#E0E0E0" BorderThickness="0,1,0,0" Padding="14,10">
                <Grid>
                  <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                  </Grid.RowDefinitions>

                  <!-- Install actions -->
                  <StackPanel x:Name="BottomInstallActions" Grid.Row="0"
                              Orientation="Horizontal" Margin="0,0,0,0" Visibility="Visible">
                    <Button x:Name="BtnInstall" Content="Install Selected"
                            Style="{StaticResource BtnAccent}"
                            IsEnabled="False" Margin="0,0,8,0"/>
                    <Button x:Name="BtnInstallCancel" Content="Cancel"
                            Style="{StaticResource BtnGhost}"
                            Visibility="Collapsed" Margin="0,0,8,0"/>
                    <TextBlock x:Name="InstallProgCount" Text=""
                               FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
                  </StackPanel>

                  <!-- Uninstall actions -->
                  <StackPanel x:Name="BottomUninstallActions" Grid.Row="0"
                              Orientation="Horizontal" Visibility="Collapsed">
                    <Button x:Name="BtnUninstall" Content="Uninstall Selected"
                            Style="{StaticResource BtnDanger}"
                            IsEnabled="False" Margin="0,0,10,0"/>
                    <TextBlock x:Name="UninstallSelTxt" Text="0 selected"
                               FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
                  </StackPanel>

                  <!-- Progress bar (install mode) -->
                  <StackPanel x:Name="InstallProgressPanel" Grid.Row="1"
                              Visibility="Collapsed" Margin="0,8,0,0">
                    <TextBlock x:Name="InstallProgLabel" Text=""
                               FontSize="11" Foreground="#888888" Margin="0,0,0,6"/>
                    <ProgressBar x:Name="InstallProgBar" Height="4"
                                 Background="#E0E0E0" Foreground="#0067C0"
                                 BorderThickness="0" Minimum="0" Maximum="100"/>
                  </StackPanel>
                </Grid>
              </Border>
            </Grid>
          </Grid>

          <!-- legacy stubs: kept so $ctrl[] lookups don't crash (Visibility=Collapsed, Width/Height=0) -->
          <Grid x:Name="PageInstall"    Visibility="Collapsed" Width="0" Height="0"/>
          <Grid x:Name="PageUninstall"  Visibility="Collapsed" Width="0" Height="0"/>
          <Grid x:Name="PageAppUpdates" Visibility="Collapsed" Width="0" Height="0"/>

          <!-- PAGE: TWEAKS -->
          <Grid x:Name="PageTweaks" Visibility="Collapsed">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Toolbar + Templates -->
            <Border Grid.Row="0" Padding="16,12" Background="#FFFFFF"
                    BorderBrush="#E8E8E8" BorderThickness="0,0,0,1">
              <StackPanel>
                <!-- Templates row -->
                <StackPanel Orientation="Horizontal" Margin="0,0,0,10">
                  <TextBlock Text="Templates:" FontSize="12" Foreground="#777777"
                             VerticalAlignment="Center" Margin="0,0,10,0"/>
                  <Button x:Name="TplNone"     Content="None"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0" Padding="12,6"/>
                  <Button x:Name="TplStandard" Content="Standard"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0" Padding="12,6"/>
                  <Button x:Name="TplMinimal"  Content="Minimal"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0" Padding="12,6"/>
                  <Button x:Name="TplHeavy"    Content="Heavy"
                          Style="{StaticResource BtnDanger}" Margin="0,0,6,0" Padding="12,6"/>
                </StackPanel>
                <!-- Controls row -->
                <StackPanel Orientation="Horizontal">
                  <TextBox x:Name="TweakSearch" Style="{StaticResource SearchBox}"
                           Width="220" Margin="0,0,10,0"/>
                  <Button x:Name="BtnCheckAll"   Content="Select All"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0"/>
                  <Button x:Name="BtnUncheckAll" Content="None"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0"/>
                  <TextBlock x:Name="TweakCountLabel" Text="0 selected"
                             FontSize="12" Foreground="#777777" VerticalAlignment="Center"
                             Margin="10,0,0,0"/>
                </StackPanel>
              </StackPanel>
            </Border>

            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
              <StackPanel x:Name="TweakPanel" Margin="16,12,16,12"/>
            </ScrollViewer>

            <Border Grid.Row="2" Background="#F5F5F5"
                    BorderBrush="#E0E0E0" BorderThickness="0,1,0,0" Padding="16,12">
              <StackPanel Orientation="Horizontal">
                <Button x:Name="BtnApplyTweaks" Content="Apply Selected Tweaks"
                        Style="{StaticResource BtnAccent}" Margin="0,0,10,0"/>
                <Button x:Name="BtnUndoTweaks"  Content="Undo Selected"
                        Style="{StaticResource BtnGhost}"/>
              </StackPanel>
            </Border>
          </Grid>

          <!-- PAGE: SERVICES -->
          <Grid x:Name="PageServices" Visibility="Collapsed">
            <Grid.RowDefinitions>
              <RowDefinition Height="*"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Auto">
              <StackPanel x:Name="ServicePanel" Margin="16,12,16,12"/>
            </ScrollViewer>
            <Border Grid.Row="1" Background="#F5F5F5"
                    BorderBrush="#E0E0E0" BorderThickness="0,1,0,0" Padding="16,12">
              <StackPanel Orientation="Horizontal">
                <Button x:Name="BtnSvcDisable" Content="Disable Selected"
                        Style="{StaticResource BtnDanger}" Margin="0,0,8,0"/>
                <Button x:Name="BtnSvcManual"  Content="Set Manual"
                        Style="{StaticResource BtnGhost}" Margin="0,0,8,0"/>
                <Button x:Name="BtnSvcEnable"  Content="Re-Enable"
                        Style="{StaticResource BtnSuccess}"/>
              </StackPanel>
            </Border>
          </Grid>

          <!-- PAGE: REPAIR -->
          <Grid x:Name="PageRepair" Visibility="Collapsed">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <WrapPanel Grid.Row="0" Margin="20,16" Orientation="Horizontal">

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#EEF6FF"
                      BorderBrush="#B8D0E8" BorderThickness="1" Width="200">
                <Button x:Name="BtnSFC" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#D8E8F8" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F6E1;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="SFC + DISM" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Full system file check" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#EEF6FF"
                      BorderBrush="#B8D0E8" BorderThickness="1" Width="200">
                <Button x:Name="BtnClearTemp" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#F5E8D8" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F5D1;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Clear Temp" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Remove junk files" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#EEF6FF"
                      BorderBrush="#B8D0E8" BorderThickness="1" Width="200">
                <Button x:Name="BtnFlushDNS" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#D8F0E8" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F310;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Flush DNS" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Clear DNS resolver cache" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#EEF6FF"
                      BorderBrush="#B8D0E8" BorderThickness="1" Width="200">
                <Button x:Name="BtnWsReset" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#EED8F0" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F6D2;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Reset Store" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Fix Microsoft Store issues" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#EEF6FF"
                      BorderBrush="#B8D0E8" BorderThickness="1" Width="200">
                <Button x:Name="BtnRestorePoint" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#D8F0DA" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F4BE;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Restore Point" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Save system snapshot now" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#EEF6FF"
                      BorderBrush="#B8D0E8" BorderThickness="1" Width="200">
                <Button x:Name="BtnNetReset" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#F5E8D8" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F504;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Network Reset" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Reset Winsock and TCP/IP" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

            </WrapPanel>

            <Border x:Name="RepairOutputBorder" Grid.Row="1" Margin="20,0,20,20" CornerRadius="10"
                    Background="#F8F8F8" BorderBrush="#E0E0E0" BorderThickness="1">
              <Grid>
                <Grid.RowDefinitions>
                  <RowDefinition Height="Auto"/>
                  <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Border x:Name="RepairOutputHeader" Grid.Row="0" Background="#F0F0F0" CornerRadius="10,10,0,0"
                        BorderBrush="#E0E0E0" BorderThickness="0,0,0,1" Padding="14,8">
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="Output" FontSize="11" FontWeight="SemiBold" Foreground="#777777"/>
                    <TextBlock x:Name="RepairSpinner" Text=" Running..." FontSize="11"
                               Foreground="#0078D4" Visibility="Collapsed"/>
                  </StackPanel>
                </Border>
                <ScrollViewer Grid.Row="1" Height="180" VerticalScrollBarVisibility="Auto">
                  <TextBox x:Name="RepairOutput" Background="Transparent"
                           Foreground="#1A1A1A" FontFamily="Consolas, Courier New"
                           FontSize="11" IsReadOnly="True" BorderThickness="0"
                           TextWrapping="Wrap" Padding="14,10"/>
                </ScrollViewer>
              </Grid>
            </Border>
          </Grid>

          <!-- PAGE: WINDOWS UPDATES -->
          <Grid x:Name="PageUpdates" Visibility="Collapsed">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="20,16">
              <Button x:Name="BtnRunUpdates"     Content="Check &amp; Install"
                      Style="{StaticResource BtnAccent}" Margin="0,0,10,0"/>
              <Button x:Name="BtnPauseUpdates"   Content="Pause 7 Days"
                      Style="{StaticResource BtnGhost}" Margin="0,0,10,0"/>
              <Button x:Name="BtnResumeUpdates"  Content="Resume Updates"
                      Style="{StaticResource BtnGhost}"/>
            </StackPanel>
            <Border x:Name="WinUpdateOutputBorder" Grid.Row="1" Margin="20,0,20,20" CornerRadius="10"
                    Background="#F8F8F8" BorderBrush="#E0E0E0" BorderThickness="1">
              <ScrollViewer VerticalScrollBarVisibility="Auto">
                <TextBox x:Name="UpdateOutput" Background="Transparent"
                         Foreground="#1A1A1A" FontFamily="Consolas, Courier New"
                         FontSize="11" IsReadOnly="True" BorderThickness="0"
                         TextWrapping="Wrap" Padding="16,12"/>
              </ScrollViewer>
            </Border>
          </Grid>

          <!-- PAGE: ABOUT -->
          <Grid x:Name="PageAbout" Visibility="Collapsed">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
              <StackPanel Margin="40,30" MaxWidth="500" HorizontalAlignment="Left">
                <Border Width="72" Height="72" CornerRadius="18" Background="Transparent"
                        Margin="0,0,0,20" HorizontalAlignment="Left">
                  <Image x:Name="AboutIcon" Width="72" Height="72"
                         RenderOptions.BitmapScalingMode="HighQuality"
                         Stretch="UniformToFill"/>
                </Border>
                <TextBlock x:Name="AboutTitle" Text="WinToolerV1" FontSize="28" FontWeight="Bold" Foreground="#1A1A1A"/>
                <TextBlock x:Name="AboutSub" Text="by ErickP (Eperez98)" FontSize="13" Foreground="#0067C0" Margin="0,4,0,20"/>

                <!-- Version info card -->
                <Border x:Name="AboutInfoCard" Background="#FFFFFF" CornerRadius="10" Padding="20,16"
                        BorderBrush="#E0E0E0" BorderThickness="1">
                  <StackPanel>
                    <Grid Margin="0,0,0,10">
                      <TextBlock Text="Version"     Foreground="#777777"/>
                      <TextBlock x:Name="AboutVersion" Text="0.6.1 BETA Build 4.100" Foreground="#1A1A1A" HorizontalAlignment="Right"/>
                    </Grid>
                    <Grid Margin="0,0,0,10">
                      <TextBlock Text="Platform"    Foreground="#777777"/>
                      <TextBlock x:Name="AboutOS"   Foreground="#1A1A1A" HorizontalAlignment="Right"/>
                    </Grid>
                    <Grid Margin="0,0,0,10">
                      <TextBlock Text="License"     Foreground="#777777"/>
                      <TextBlock Text="GPL-3.0"     Foreground="#00CC6A" HorizontalAlignment="Right"/>
                    </Grid>
                    <Grid Margin="0,0,0,10">
                      <TextBlock Text="Inspired by" Foreground="#777777"/>
                      <TextBlock Text="ChrisTitusTech/winutil" Foreground="#0078D4" HorizontalAlignment="Right"/>
                    </Grid>
                    <Grid Margin="0,0,0,12">
                      <TextBlock Text="GitHub"      Foreground="#777777"/>
                      <TextBlock Text="github.com/eperez98" Foreground="#0078D4" HorizontalAlignment="Right"/>
                    </Grid>
                    <Grid>
                      <TextBlock Text="Log file"    Foreground="#777777"/>
                      <TextBlock x:Name="LogPathTxt" Foreground="#444444" FontSize="10"
                                 HorizontalAlignment="Right" VerticalAlignment="Center" TextWrapping="Wrap" MaxWidth="260"/>
                    </Grid>
                  </StackPanel>
                </Border>

                <Button x:Name="BtnOpenLog" Content="Open Log File"
                        Style="{StaticResource BtnGhost}"
                        Margin="0,16,0,20" HorizontalAlignment="Left"/>

                <!-- Roadmap: v0.7 BETA - Tools Expansion -->
                <TextBlock Text="v0.7 BETA  -  Tools Expansion" FontSize="12" FontWeight="SemiBold"
                           Foreground="#0067C0" Margin="0,8,0,8"/>
                <Border Background="#F0F7FF" CornerRadius="10" Padding="18,14"
                        BorderBrush="#C5DCF5" BorderThickness="1" Margin="0,0,0,16">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#0067C0" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Driver Updater</Run>
                        <Run Foreground="#666666"> - Scan and update outdated device drivers via winget or vendor sources</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#0067C0" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Startup Manager</Run>
                        <Run Foreground="#666666"> - View, enable and disable startup programs and scheduled tasks</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#0067C0" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Hosts File Editor</Run>
                        <Run Foreground="#666666"> - Visual editor with ad-block and privacy presets built in</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#0067C0" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">DNS Changer</Run>
                        <Run Foreground="#666666"> - Quick switch between Cloudflare, Google, Quad9 and custom DNS</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#x25CF;" Foreground="#0067C0" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Profile Backup</Run>
                        <Run Foreground="#666666"> - Export and restore tweak configs as shareable JSON files</Run>
                      </TextBlock>
                    </StackPanel>
                  </StackPanel>
                </Border>

                <!-- Roadmap: v0.8 BETA - Power Features -->
                <TextBlock Text="v0.8 BETA  -  Power Features" FontSize="12" FontWeight="SemiBold"
                           Foreground="#C45000" Margin="0,0,0,8"/>
                <Border Background="#FFF8F0" CornerRadius="10" Padding="18,14"
                        BorderBrush="#F0D0A8" BorderThickness="1" Margin="0,0,0,16">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#C45000" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Performance Benchmarks</Run>
                        <Run Foreground="#666666"> - Before / after CPU, RAM and disk scoring via WinSAT</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#C45000" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Registry Cleaner</Run>
                        <Run Foreground="#666666"> - Orphaned key scan with preview and full undo support</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#C45000" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">WSL Manager</Run>
                        <Run Foreground="#666666"> - Install, update and manage Linux distros from the GUI</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#C45000" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Custom Tweak Builder</Run>
                        <Run Foreground="#666666"> - Create and save your own registry and service tweaks in-app</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#x25CF;" Foreground="#C45000" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">More Languages</Run>
                        <Run Foreground="#666666"> - French, Portuguese, German and Italian UI translations</Run>
                      </TextBlock>
                    </StackPanel>
                  </StackPanel>
                </Border>

                <!-- Roadmap: v1.0 Release Candidate -->
                <TextBlock Text="v1.0 Release Candidate  -  Stability and Polish" FontSize="12" FontWeight="SemiBold"
                           Foreground="#107C10" Margin="0,0,0,8"/>
                <Border Background="#F0FFF4" CornerRadius="10" Padding="18,14"
                        BorderBrush="#A8DFB0" BorderThickness="1" Margin="0,0,0,20">
                  <StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#107C10" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Zero known bugs</Run>
                        <Run Foreground="#666666"> - All BETA cycle issues resolved before tagging 1.0</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#107C10" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Installer</Run>
                        <Run Foreground="#666666"> - Proper .msi or NSIS installer with Start Menu shortcut and clean uninstall</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#107C10" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Auto-Update Check</Run>
                        <Run Foreground="#666666"> - In-app notification when a new version is available on GitHub</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#107C10" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Code-Signed Script</Run>
                        <Run Foreground="#666666"> - Eliminates SmartScreen warnings on first run</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#x25CF;" Foreground="#107C10" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Full OS Test Coverage</Run>
                        <Run Foreground="#666666"> - Win10 21H2 and Win11 22H2, 23H2, 24H2 on Intel, AMD and ARM64</Run>
                      </TextBlock>
                    </StackPanel>
                  </StackPanel>
                </Border>

              </StackPanel>
            </ScrollViewer>
          </Grid>

        </Grid>
      </Grid>
    </Grid>

    <!-- Status bar -->
    <Border x:Name="StatusBorder" Grid.Row="1" Background="#F8F9FA"
            BorderBrush="#E5E5E5" BorderThickness="0,1,0,0" Padding="20,5">
      <Grid>
        <TextBlock x:Name="StatusBar" Text="Ready"
                   Foreground="#444444" FontSize="11" FontFamily="Consolas, Courier New"/>
        <TextBlock x:Name="ClockText" HorizontalAlignment="Right"
                   Foreground="#333333" FontSize="11" FontFamily="Consolas, Courier New"/>
      </Grid>
    </Border>
  </Grid>
</Window>
'@

    # Load window
    $reader = New-Object System.Xml.XmlNodeReader($XAML)
    $win    = [Windows.Markup.XamlReader]::Load($reader)

    # ----------------------------------------------------------------
    #  GET CONTROLS
    # ----------------------------------------------------------------
    $ctrl = @{}
    $names = @(
        "Sidebar","PageHeader","StatusBorder",
        "NavApps","NavInstall","NavUninstall","NavAppUpdates","NavTweaks","NavServices","NavRepair","NavUpdates","NavAbout",
        "PageApps","PageInstall","PageUninstall","PageAppUpdates","PageTweaks","PageServices","PageRepair","PageUpdates","PageAbout",
        "PageTitle","PageSubtitle","OsBadge","WingetDot","WingetStatus","AboutOS",

        "AppsModeBar","ModePillInstall","ModePillUninstall","BtnUpdateAllApps","ModeLblInstall","ModeLblUninstall","ModeLblUpdateAll","InstallSearch","CatPanel","AppPanel","BtnSelectAll","BtnDeselectAll","SelCountTxt",
        "BtnInstall","BtnInstallCancel","InstallProgressPanel","InstallProgLabel","InstallProgCount","InstallProgBar",
        "InstallScroll","UninstallScroll","BottomInstallActions","BottomUninstallActions","UninstallPanel","UninstallCount","BtnRefreshUninstall","BtnUninstall","UninstallSelTxt",
        "TweakSearch","TweakPanel","TweakCountLabel","BtnCheckAll","BtnUncheckAll","BtnApplyTweaks","BtnUndoTweaks",
        "TplNone","TplStandard","TplMinimal","TplHeavy",
        "ServicePanel","BtnSvcDisable","BtnSvcManual","BtnSvcEnable",
        "BtnSFC","BtnClearTemp","BtnFlushDNS","BtnWsReset","BtnRestorePoint","BtnNetReset",
        "RepairOutput","RepairSpinner",
        "BtnRunUpdates","BtnPauseUpdates","BtnResumeUpdates","UpdateOutput",
        "BtnOpenLog","LogPathTxt","StatusBar","ClockText",
        "CatSidebar","InstallToolbar","SelCountBadge","InstallBottomBar",
        "SidebarTitle","SidebarSub","SidebarFooter","WingetLabel",
        
        "TweaksToolbar","TweaksBottomBar","ServicesBottomBar",
        "RepairOutputBorder","RepairOutputHeader","WinUpdateOutputBorder",
        "AboutInfoCard","RoadmapV7Card","RoadmapV8Card",
        "AboutTitle","AboutSub","AboutVersion",
        "SidebarIcon","AboutIcon",
        "BtnLangEN","BtnLangES","LangLabel"
    )
    foreach ($n in $names) { $ctrl[$n] = $win.FindName($n) }

    # ----------------------------------------------------------------
    #  THEME APPLY FUNCTION
    # ----------------------------------------------------------------
    function script:Apply-Theme {
        param([bool]$dark)
        $script:IsDark = $false
        & script:Set-Theme $false
        $t = $script:T

        # Window + chrome
        $win.Background = script:Brush $t.WinBG
        $ctrl["Sidebar"].Background          = script:Brush $t.SidebarBG
        $ctrl["Sidebar"].BorderBrush         = script:Brush $t.SidebarBorder
        $ctrl["PageHeader"].Background       = script:Brush $t.Surface1
        $ctrl["PageHeader"].BorderBrush      = script:Brush $t.Border1
        $ctrl["StatusBorder"].Background     = script:Brush $t.StatusBG
        $ctrl["StatusBorder"].BorderBrush    = script:Brush $t.StatusBorder
        $ctrl["StatusBar"].Foreground        = script:Brush $t.Text4
        $ctrl["ClockText"].Foreground        = script:Brush $t.Text4
        $ctrl["PageTitle"].Foreground        = script:Brush $t.Text1
        $ctrl["PageSubtitle"].Foreground     = script:Brush $t.Text3


        # Helper to recursively repaint all WPF elements by type
        function script:Repaint-Tree {
            param($root)
            if ($null -eq $root) { return }
            $type = $root.GetType().Name
            switch ($type) {
                "Border" {
                    $tag = $root.Tag
                    if ($tag -eq "card") {
                        $root.Background  = script:Brush $t.CardBG
                        $root.BorderBrush = script:Brush $t.CardBorder
                    } elseif ($tag -eq "surface") {
                        $root.Background  = script:Brush $t.Surface2
                        $root.BorderBrush = script:Brush $t.Border1
                    } elseif ($tag -eq "input") {
                        $root.Background  = script:Brush $t.InputBG
                        $root.BorderBrush = script:Brush $t.Border2
                    } elseif ($tag -eq "header") {
                        $root.Background  = script:Brush $t.Surface1
                        $root.BorderBrush = script:Brush $t.Border1
                    } elseif ($tag -eq "output") {
                        $root.Background  = script:Brush "#F8F8F8"
                        $root.BorderBrush = script:Brush $t.Border1
                    }
                }
                "TextBox" {
                    if ($root.IsReadOnly) {
                        $root.Foreground = script:Brush $t.Green
                        $root.Background = script:Brush "Transparent"
                    } else {
                        $root.Background  = script:Brush $t.InputBG
                        $root.Foreground  = script:Brush $t.Text1
                        $root.BorderBrush = script:Brush $t.Border2
                    }
                }
                "TextBlock" {
                    $tag = $root.Tag
                    if     ($tag -eq "muted")  { $root.Foreground = script:Brush $t.Text3 }
                    elseif ($tag -eq "label")  { $root.Foreground = script:Brush $t.Text2 }
                    elseif ($tag -eq "title")  { $root.Foreground = script:Brush $t.Text1 }
                    elseif ($tag -eq "section"){ $root.Foreground = script:Brush $t.Text3 }
                }
                "ComboBox" {
                    $root.Background  = script:Brush $t.InputBG
                    $root.Foreground  = script:Brush $t.Text1
                    $root.BorderBrush = script:Brush $t.Border2
                }
                "ScrollViewer" {
                    $root.Background = script:Brush "Transparent"
                }
            }
            # Walk children
            try {
                $children = switch ($type) {
                    "Grid"         { $root.Children }
                    "StackPanel"   { $root.Children }
                    "WrapPanel"    { $root.Children }
                    "DockPanel"    { $root.Children }
                    "Border"       { if ($root.Child) { @($root.Child) } else { @() } }
                    "ScrollViewer" { if ($root.Content) { @($root.Content) } else { @() } }
                    "ContentPresenter" { @() }
                    default        { @() }
                }
                foreach ($ch in $children) { script:Repaint-Tree $ch }
            } catch {}
        }

        # Paint the main content area
        $mainGrid = $win.Content
        if ($mainGrid) { script:Repaint-Tree $mainGrid }

        # Nav buttons - repaint all with current theme colors
        $navPageMap = @{
            "NavApps"    = "Apps"
            "NavTweaks"="Tweaks"; "NavServices"="Services"; "NavRepair"="Repair"
            "NavUpdates"="Updates"; "NavAbout"="About"
        }
        foreach ($n in $navPageMap.Keys) {
            if ($ctrl[$n]) {
                $isActive = ($script:CurrentPage -eq $navPageMap[$n])
                if ($isActive) {
                    $ctrl[$n].Background = script:Brush $t.NavActBG
                    $ctrl[$n].Foreground = script:Brush $t.NavActFG
                    $ctrl[$n].FontWeight = [Windows.FontWeights]::SemiBold
                } else {
                    $ctrl[$n].Background = [Windows.Media.Brushes]::Transparent
                    $ctrl[$n].Foreground = script:Brush $t.NavBtnFG
                    $ctrl[$n].FontWeight = [Windows.FontWeights]::Normal
                }
            }
        }
        # Repaint nav icon badge backgrounds via $script:T token system
        # Walk the nav StackPanel and update every badge Border + its inner TextBlock
        $badgeTokens = @(
            @{ BG="BadgeInstallBG";   FG="BadgeInstallFG";   Icon="&#x2B07;" }
            @{ BG="BadgeUninstallBG"; FG="BadgeUninstallFG"; Icon="&#x2715;" }
            @{ BG="BadgeUpdatesBG";   FG="BadgeUpdatesFG";   Icon="&#x2B06;" }
            @{ BG="BadgeTweaksBG";    FG="BadgeTweaksFG";    Icon="&#x2699;" }
            @{ BG="BadgeServicesBG";  FG="BadgeServicesFG";  Icon="&#x25B6;" }
            @{ BG="BadgeRepairBG";    FG="BadgeRepairFG";    Icon="&#x1F527;" }
            @{ BG="BadgeWinUpdBG";    FG="BadgeWinUpdFG";    Icon="&#x21BA;" }
            @{ BG="BadgeAboutBG";     FG="BadgeAboutFG";     Icon="&#x2139;" }
        )
        if ($ctrl["Sidebar"]) {
            $sGrid = $ctrl["Sidebar"].Child
            if ($sGrid -and $sGrid.GetType().Name -eq "Grid") {
                foreach ($row in $sGrid.Children) {
                    if ($row.GetType().Name -eq "StackPanel") {
                        $tokenIdx = 0
                        foreach ($btn in $row.Children) {
                            if ($btn.GetType().Name -eq "Button" -and $tokenIdx -lt $badgeTokens.Count) {
                                try {
                                    $sp = $btn.Content
                                    if ($sp -and $sp.GetType().Name -eq "StackPanel") {
                                        $bd = $sp.Children[0]
                                        if ($bd -and $bd.GetType().Name -eq "Border" -and
                                            $bd.Width -eq 22) {
                                            $tkBG = $badgeTokens[$tokenIdx].BG
                                            $tkFG = $badgeTokens[$tokenIdx].FG
                                            if ($t.ContainsKey($tkBG)) { $bd.Background = script:Brush $t[$tkBG] }
                                            if ($bd.Child -and $t.ContainsKey($tkFG)) {
                                                $bd.Child.Foreground = script:Brush $t[$tkFG]
                                            }
                                            $tokenIdx++
                                        }
                                    }
                                } catch {}
                            }
                        }
                        break
                    }
                }
            }
        }

        # Sidebar logo texts
        if ($ctrl["SidebarTitle"])  { $ctrl["SidebarTitle"].Foreground = script:Brush $t.Text1 }
        if ($ctrl["SidebarSub"])    { $ctrl["SidebarSub"].Foreground   = script:Brush $t.Text3 }
        if ($ctrl["WingetLabel"])   { $ctrl["WingetLabel"].Foreground  = script:Brush $t.Text2 }
        if ($ctrl["WingetStatus"])  { $ctrl["WingetStatus"].Foreground = script:Brush $t.Text3 }
        if ($ctrl["OsBadge"])       { $ctrl["OsBadge"].Foreground      = script:Brush $t.Text4 }
        if ($ctrl["SidebarFooter"]) {
            $ctrl["SidebarFooter"].Background  = script:Brush $t.Surface2
            $ctrl["SidebarFooter"].BorderBrush = script:Brush $t.Border1
        }
        # Sidebar section labels (APPS/SYSTEM/TOOLS) - walk nav StackPanel
        if ($ctrl["Sidebar"]) {
            $sg = $ctrl["Sidebar"].Child
            if ($sg -and $sg.GetType().Name -eq "Grid") {
                foreach ($child in $sg.Children) {
                    if ($child.GetType().Name -eq "StackPanel") {
                        foreach ($el in $child.Children) {
                            if ($el.GetType().Name -eq "TextBlock" -and $el.FontSize -eq 9) {
                                $el.Foreground = script:Brush $t.Text4
                            }
                        }
                        break
                    }
                }
            }
        }

        # Page backgrounds - ensure all pages switch
        $pageNames = @("PageApps","PageTweaks",
                       "PageServices","PageRepair","PageUpdates","PageAbout")
        foreach ($n in $pageNames) {
            if ($ctrl[$n]) { $ctrl[$n].Background = script:Brush $t.WinBG }
        }

        # -- Repaint all hardcoded-dark XAML surfaces -----------------------------
        # Toolbars and sidebars
        $surfaceNames = @(
            "CatSidebar","InstallToolbar","AppsModeBar","TweaksToolbar"
        )
        foreach ($n in $surfaceNames) {
            if ($ctrl[$n]) {
                $ctrl[$n].Background  = script:Brush $t.Surface1
                $ctrl[$n].BorderBrush = script:Brush $t.Border1
            }
        }
        # Bottom action bars
        $bottomNames = @(
            "InstallBottomBar",
            "TweaksBottomBar","ServicesBottomBar"
        )
        foreach ($n in $bottomNames) {
            if ($ctrl[$n]) {
                $ctrl[$n].Background  = script:Brush $t.StatusBG
                $ctrl[$n].BorderBrush = script:Brush $t.Border1
            }
        }
        # SelCount badge
        if ($ctrl["SelCountBadge"]) {
            $ctrl["SelCountBadge"].Background = script:Brush $t.Surface2
        }
        # Output terminal borders (always stay near-black regardless of theme)
        foreach ($n in @("RepairOutputBorder","WinUpdateOutputBorder")) {
            if ($ctrl[$n]) {
                $ctrl[$n].Background  = script:Brush "#F8F8F8"
                $ctrl[$n].BorderBrush = script:Brush $t.Border1
            }
        }
        foreach ($n in @("RepairOutputHeader")) {
            if ($ctrl[$n]) {
                $ctrl[$n].Background  = script:Brush "#F0F0F0"
                $ctrl[$n].BorderBrush = script:Brush $t.Border1
            }
        }
        # About page info card
        if ($ctrl["AboutInfoCard"]) {
            $ctrl["AboutInfoCard"].Background  = script:Brush $t.Surface1
            $ctrl["AboutInfoCard"].BorderBrush = script:Brush $t.Border1
        }
        # Roadmap cards keep their tinted colors but border switches
        if ($ctrl["RoadmapV7Card"]) { $ctrl["RoadmapV7Card"].BorderBrush = script:Brush $t.Border1 }
        if ($ctrl["RoadmapV8Card"]) { $ctrl["RoadmapV8Card"].BorderBrush = script:Brush $t.Border1 }
        # About page text
        if ($ctrl["AboutTitle"])   { $ctrl["AboutTitle"].Foreground   = script:Brush $t.Text1 }
        if ($ctrl["AboutVersion"]) { $ctrl["AboutVersion"].Foreground = script:Brush $t.Text1 }
        if ($ctrl["AboutOS"])      { $ctrl["AboutOS"].Foreground      = script:Brush $t.Text1 }


        # Explicit control overrides (controls without Tag that need specific colours)
        $specText = @(
            "PageTitle","PageSubtitle","WingetStatus","OsBadge","RepairSpinner",
            "StatusBar","ClockText","InstallProgLabel","InstallProgCount",
            "TweakCountLabel","UninstallCount","UninstallSelTxt"
        )
        foreach ($n in $specText) {
            if ($ctrl[$n]) { $ctrl[$n].Foreground = script:Brush $t.Text2 }
        }
        # Titles stay bright
        if ($ctrl["PageTitle"])    { $ctrl["PageTitle"].Foreground    = script:Brush $t.Text1 }
        if ($ctrl["PageSubtitle"]) { $ctrl["PageSubtitle"].Foreground = script:Brush $t.Text3 }

        # Search boxes
        foreach ($n in @("InstallSearch","TweakSearch")) {
            if ($ctrl[$n]) {
                $ctrl[$n].Background  = script:Brush $t.InputBG
                $ctrl[$n].Foreground  = script:Brush $t.Text1
                $ctrl[$n].BorderBrush = script:Brush $t.Border2
            }
        }

        # Output consoles always stay dark with green text
        foreach ($n in @("RepairOutput","UpdateOutput")) {
            if ($ctrl[$n]) {
                $ctrl[$n].Foreground = script:Brush $t.Text1
                $ctrl[$n].Background = script:Brush "Transparent"
            }
        }

        # Rebuild dynamic panels so they pick up new $script:T token values
        # Only rebuild if the panels have already been populated (i.e. after Add_Loaded)
        if ($ctrl["AppPanel"] -and $ctrl["AppPanel"].Children.Count -gt 0) {
            # Repaint AppPanel rows in-place (faster than rebuild)
            foreach ($child in $ctrl["AppPanel"].Children) {
                if ($child.GetType().Name -eq "Border" -and $child.Tag -and $child.Tag.GetType().Name -eq "String" -and $child.Tag -ne "") {
                    $child.Background = [Windows.Media.Brushes]::Transparent
                }
                if ($child.GetType().Name -eq "Grid") {
                    # category header grid - repaint divider line
                    foreach ($gc in $child.Children) {
                        if ($gc.GetType().Name -eq "Border" -and $gc.Child -and $gc.Child.GetType().Name -eq "TextBlock" -and $gc.Child.FontWeight -eq [Windows.FontWeights]::Bold) {
                            # pill label - leave tinted
                        } elseif ($gc.GetType().Name -eq "Border" -and $null -eq $gc.Child) {
                            $gc.Background = script:Brush $t.Border1
                        }
                    }
                }
            }
            # Repaint text inside app rows
            foreach ($row in ($ctrl["AppPanel"].Children | Where-Object { $_.GetType().Name -eq "Border" -and $_.Child -and $_.Child.GetType().Name -eq "Grid" })) {
                $grid = $row.Child
                foreach ($col in $grid.Children) {
                    if ($col.GetType().Name -eq "StackPanel") {
                        $children = @($col.Children)
                        if ($children.Count -ge 1) { $children[0].Foreground = script:Brush $t.Text1 }  # name
                        if ($children.Count -ge 2) { $children[1].Foreground = script:Brush $t.Text3 }  # desc
                        if ($children.Count -ge 3) { $children[2].Foreground = script:Brush $t.Text4 }  # id
                    }
                }
            }
        }

        if ($ctrl["TweakPanel"] -and $ctrl["TweakPanel"].Children.Count -gt 0) {
            foreach ($child in $ctrl["TweakPanel"].Children) {
                $tn = $child.GetType().Name
                if ($tn -eq "Border" -and $child.Child -and $child.Child.GetType().Name -eq "Grid") {
                    $child.Background  = script:Brush $t.CardBG
                    $child.BorderBrush = script:Brush $t.CardBorder
                    $grid = $child.Child
                    foreach ($col in $grid.Children) {
                        if ($col.GetType().Name -eq "StackPanel") {
                            $kids = @($col.Children)
                            if ($kids.Count -ge 1) { $kids[0].Foreground = script:Brush $t.Text1 }
                            if ($kids.Count -ge 2) { $kids[1].Foreground = script:Brush $t.Text3 }
                        }
                    }
                } elseif ($tn -eq "TextBlock") {
                    $child.Foreground = script:Brush $t.Text3
                }
            }
        }

        if ($ctrl["ServicePanel"] -and $ctrl["ServicePanel"].Children.Count -gt 0) {
            foreach ($card in $ctrl["ServicePanel"].Children) {
                if ($card.GetType().Name -eq "Border" -and $card.Child -and $card.Child.GetType().Name -eq "Grid") {
                    $card.Background  = script:Brush $t.CardBG
                    $card.BorderBrush = script:Brush $t.CardBorder
                    $grid = $card.Child
                    foreach ($col in $grid.Children) {
                        if ($col.GetType().Name -eq "StackPanel") {
                            $kids = @($col.Children)
                            if ($kids.Count -ge 1) { $kids[0].Foreground = script:Brush $t.Text1 }
                            if ($kids.Count -ge 2) { $kids[1].Foreground = script:Brush $t.Text3 }
                            if ($kids.Count -ge 3) { $kids[2].Foreground = script:Brush $t.Text4 }
                        }
                    }
                }
            }
        }

        if ($ctrl["UninstallPanel"] -and $ctrl["UninstallPanel"].Children.Count -gt 0) {
            foreach ($row in $ctrl["UninstallPanel"].Children) {
                if ($row.GetType().Name -eq "Border" -and $row.Child -and $row.Child.GetType().Name -eq "Grid") {
                    $row.Background  = script:Brush $t.CardBG
                    $row.BorderBrush = script:Brush $t.CardBorder
                    $grid = $row.Child
                    foreach ($col in $grid.Children) {
                        if ($col.GetType().Name -eq "StackPanel") {
                            $kids = @($col.Children)
                            if ($kids.Count -ge 1) { $kids[0].Foreground = script:Brush $t.Text1 }
                            if ($kids.Count -ge 2) { $kids[1].Foreground = script:Brush $t.Text4 }
                        }
                        if ($col.GetType().Name -eq "TextBlock") {
                            $col.Foreground = script:Brush $t.Text3
                        }
                    }
                }
            }
        }

        # CatPanel label colors
        if ($ctrl["CatPanel"]) {
            foreach ($bd in $ctrl["CatPanel"].Children) {
                if ($bd.GetType().Name -eq "Border" -and $bd.Child -and $bd.Child.GetType().Name -eq "StackPanel") {
                    $sp = $bd.Child
                    foreach ($elem in $sp.Children) {
                        if ($elem.GetType().Name -eq "TextBlock" -and $elem.FontSize -eq 12) {
                            # Main category label - active or inactive
                            if ($bd.Background -and $bd.Background.Color.A -gt 10) {
                                $elem.Foreground = script:Brush $t.NavActFG
                            } else {
                                $elem.Foreground = script:Brush $t.Text3
                            }
                        }
                    }
                }
            }
        }
    }

    # ----------------------------------------------------------------
    #  HELPERS
    # ----------------------------------------------------------------
    $pages   = @("Apps","Tweaks","Services","Repair","Updates","About")
    $navBtns = @{
        "Apps"       = $ctrl["NavApps"]
        "Tweaks"     = $ctrl["NavTweaks"]
        "Services"   = $ctrl["NavServices"]
        "Repair"     = $ctrl["NavRepair"]
        "Updates"    = $ctrl["NavUpdates"]
        
        "About"      = $ctrl["NavAbout"]
    }
    $pageTitles = @{
        "Apps"       = @("Applications",                 "Install, uninstall or update apps via winget")
        "Tweaks"     = @("System Tweaks",                "Apply performance, privacy and UI optimisations")
        "Services"   = @("Windows Services",             "Manage and disable unnecessary background services")
        "Repair"     = @("Repair & Maintenance",         "Diagnose and fix common Windows issues")
        "Updates"    = @("Windows Updates",              "Check, install, pause or resume Windows updates")
        
        "About"      = @("About WinToolerV1",            "Version information and credits")
    }

    $navStyleActive   = $win.Resources["NavBtnActive"]   # kept for reference
    $navStyleInactive = $win.Resources["NavBtn"]              # kept for reference
    $script:CurrentPage = "Apps"
    $script:AppsMode    = "Install"   # "Install" | "Uninstall"
    $script:setStatus = { param($msg, $color = "#444444")
        $ctrl["StatusBar"].Text       = $msg
        $ctrl["StatusBar"].Foreground = script:Brush $color
        Write-WTLog $msg
        Write-Host "  [STATUS] $msg" -ForegroundColor DarkGray
    }

    $switchPage = {
        param($page)
        foreach ($p in $pages) {
            $ctrl["Page$p"].Visibility = if ($p -eq $page) { "Visible" } else { "Collapsed" }
            if ($navBtns.ContainsKey($p)) {
                $btn = $navBtns[$p]
                if ($p -eq $page) {
                    $btn.Background = script:Brush $script:T.NavActBG
                    $btn.Foreground = script:Brush $script:T.NavActFG
                    $btn.FontWeight = [Windows.FontWeights]::SemiBold
                } else {
                    $btn.Background = [Windows.Media.Brushes]::Transparent
                    $btn.Foreground = script:Brush $script:T.NavBtnFG
                    $btn.FontWeight = [Windows.FontWeights]::Normal
                }
            }
        }
        $ctrl["PageTitle"].Text    = $pageTitles[$page][0]
        $ctrl["PageSubtitle"].Text = $pageTitles[$page][1]
        $script:CurrentPage = $page
    }

    foreach ($p in $pages) {
        $pg = $p
        if ($navBtns.ContainsKey($pg)) {
            $navBtns[$pg].Add_Click({ & $switchPage $pg }.GetNewClosure())
        }
    }

    # ── Apps mode switcher (Install / Uninstall / Updates) ──────────────
    $switchAppsMode = { param([string]$mode)
        $script:AppsMode = $mode

        # Active pill colors
        $accent   = "#0067C0"; $accentFG = "#FFFFFF"
        $inactBG  = "Transparent"; $inactFG = "#5A6A7A"

        $isInstall   = ($mode -eq "Install")
        $isUninstall = ($mode -eq "Uninstall")
        # Pill backgrounds
        $bgI = if ($isInstall)   { $accent }  else { $inactBG }
        $fgI = if ($isInstall)   { $accentFG } else { $inactFG }
        $bgU = if ($isUninstall) { $accent }  else { $inactBG }
        $fgU = if ($isUninstall) { $accentFG } else { $inactFG }
        if ($ctrl["ModePillInstall"]) {
            $ctrl["ModePillInstall"].Background = script:Brush $bgI
            if ($ctrl["ModeLblInstall"]) { $ctrl["ModeLblInstall"].Foreground = script:Brush $fgI }
            $ctrl["ModePillInstall"].FindName("iconI") | Out-Null
            # Update arrow icon color
            $sp = $ctrl["ModePillInstall"].Child
            if ($sp -and $sp.GetType().Name -eq "StackPanel") {
                $ic = $sp.Children | Select-Object -First 1
                if ($ic) { $ic.Foreground = script:Brush $fgI }
            }
        }
        if ($ctrl["ModePillUninstall"]) {
            $ctrl["ModePillUninstall"].Background = script:Brush $bgU
            if ($ctrl["ModeLblUninstall"]) { $ctrl["ModeLblUninstall"].Foreground = script:Brush $fgU }
            $sp = $ctrl["ModePillUninstall"].Child
            if ($sp -and $sp.GetType().Name -eq "StackPanel") {
                $ic = $sp.Children | Select-Object -First 1
                if ($ic) { $ic.Foreground = script:Brush $fgU }
            }
        }

        # Show/hide content panels
        if ($ctrl["InstallScroll"])  { $ctrl["InstallScroll"].Visibility  = if ($isInstall)   { "Visible" } else { "Collapsed" } }
        if ($ctrl["UninstallScroll"]) { $ctrl["UninstallScroll"].Visibility = if ($isUninstall) { "Visible" } else { "Collapsed" } }
        # Show/hide bottom action panels
        if ($ctrl["BottomInstallActions"])   { $ctrl["BottomInstallActions"].Visibility   = if ($isInstall)   { "Visible" } else { "Collapsed" } }
        if ($ctrl["BottomUninstallActions"]) { $ctrl["BottomUninstallActions"].Visibility = if ($isUninstall) { "Visible" } else { "Collapsed" } }
        # Toolbar selection controls - show only in Install mode
        if ($ctrl["BtnSelectAll"])   { $ctrl["BtnSelectAll"].Visibility   = if ($isInstall) { "Visible" } else { "Collapsed" } }
        if ($ctrl["BtnDeselectAll"]) { $ctrl["BtnDeselectAll"].Visibility = if ($isInstall) { "Visible" } else { "Collapsed" } }
        if ($ctrl["SelCountBadge"])  { $ctrl["SelCountBadge"].Visibility  = if ($isInstall) { "Visible" } else { "Collapsed" } }

        # Uninstall-specific toolbar controls
        if ($ctrl["BtnRefreshUninstall"]) { $ctrl["BtnRefreshUninstall"].Visibility = if ($isUninstall) { "Visible" } else { "Collapsed" } }
        if ($ctrl["UninstallCount"])      { $ctrl["UninstallCount"].Visibility      = if ($isUninstall) { "Visible" } else { "Collapsed" } }

        # Category sidebar: show only in Install mode (uninstall/updates don't use categories)
        if ($ctrl["CatSidebar"]) { $ctrl["CatSidebar"].Visibility = if ($isInstall) { "Visible" } else { "Collapsed" } }

        # Update progress panel visibility
        if (-not $isInstall -and $ctrl["InstallProgressPanel"]) {
            $ctrl["InstallProgressPanel"].Visibility = "Collapsed"
        }

        # Trigger data load for modes that need it
        if ($isUninstall) {
            if ($script:UninstallCache.Count -eq 0) {
                & script:Fetch-UninstallData
            }
            & script:Build-UninstallList
        }
        # Update page subtitle to reflect current mode
        $modeSubtitles = @{
            "Install"   = if ($script:lang -eq "ES") { "Selecciona e instala apps via winget" } else { "Select and install apps via winget" }
            "Uninstall" = if ($script:lang -eq "ES") { "Elimina apps instaladas en tu sistema" } else { "Remove installed apps from your system" }
        }
        if ($ctrl["PageSubtitle"] -and $modeSubtitles.ContainsKey($mode)) {
            $ctrl["PageSubtitle"].Text = $modeSubtitles[$mode]
        }
    }

    # Wire mode pill clicks
    $ctrl["ModePillInstall"].Add_MouseLeftButtonUp({   & $switchAppsMode "Install"   })
    $ctrl["ModePillUninstall"].Add_MouseLeftButtonUp({ & $switchAppsMode "Uninstall" })

    # Update All Apps — launches external PowerShell window, never blocks the UI
    $ctrl["BtnUpdateAllApps"].Add_MouseLeftButtonUp({
        if (-not $global:WingetPath) {
            [System.Windows.MessageBox]::Show(
                "winget not found. Please install App Installer from the Microsoft Store.",
                "WinTooler - winget not found",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
            return
        }
        $ps = "Write-Host '  WinTooler - Update All Apps' -ForegroundColor Cyan; " +
              "Write-Host '  Running: winget upgrade --all --accept-source-agreements --accept-package-agreements -h' -ForegroundColor DarkGray; " +
              "Write-Host ''; " +
              "& '$($global:WingetPath)' upgrade --all --accept-source-agreements --accept-package-agreements -h; " +
              "Write-Host ''; " +
              "Write-Host '  Done. Press any key to close...' -ForegroundColor Green; " +
              "`$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"
        Start-Process "powershell.exe" -ArgumentList "-NoProfile -NoLogo -ExecutionPolicy Bypass -Command `"$ps`"" -WindowStyle Normal
        Write-WTLog "Launched external winget upgrade --all -h"
    })
    $ctrl["BtnUpdateAllApps"].Add_MouseEnter({
        $ctrl["BtnUpdateAllApps"].Background = New-Object Windows.Media.SolidColorBrush(
            [Windows.Media.Color]::FromArgb(25, 16, 124, 16))
    })
    $ctrl["BtnUpdateAllApps"].Add_MouseLeave({
        $ctrl["BtnUpdateAllApps"].Background = $transpBG
    })
    # Clock
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromSeconds(1)
    $timer.Add_Tick({ $ctrl["ClockText"].Text = Get-Date -Format "HH:mm:ss  ddd dd MMM" })
    $timer.Start()

    # Theme toggle


    # OS / winget badges
    $ctrl["OsBadge"].Text    = "$($global:OSLabel) Build $($global:OSBuild)"
    $ctrl["LogPathTxt"].Text = $global:LogFile
    $ctrl["AboutOS"].Text    = "$($global:OSLabel) Build $($global:OSBuild)"

    # ----------------------------------------------------------------
    #  APPLY-LANGUAGE  — builds $S from current $lang, updates all controls
    #  Call at startup AND whenever the in-app toggle is clicked
    # ----------------------------------------------------------------
    function script:Build-StringTable { param([string]$l)
        if ($l -eq "ES") {
            return @{
                NavApps       = "Aplicaciones"
                NavInstall    = "Instalar Apps";    NavUninstall   = "Desinstalar"
                NavAppUpdates = "Act. de Apps";     NavTweaks      = "Ajustes"
                NavServices   = "Servicios";        NavRepair      = "Reparar"
                NavUpdates    = "Windows Update";   NavAbout       = "Acerca de"
                TitleApps       = "Aplicaciones"
                SubApps         = "Instala, desinstala o actualiza apps via winget"
                ModeLblInstall   = "Instalar"
                ModeLblUninstall = "Desinstalar"
                TitleInstall    = "Instalar Aplicaciones"
                SubInstall      = "Selecciona las apps a instalar via winget"
                TitleUninstall  = "Desinstalar Aplicaciones"
                SubUninstall    = "Elimina apps administradas por winget"
                TitleAppUpdates = "Actualizaciones de Apps"
                SubAppUpdates   = "Apps con actualizaciones disponibles"
                TitleTweaks     = "Ajustes del Sistema"
                SubTweaks       = "Optimizacion de rendimiento, privacidad e interfaz"
                TitleServices   = "Servicios de Windows"
                SubServices     = "Gestiona servicios en segundo plano"
                TitleRepair     = "Reparacion y Mantenimiento"
                SubRepair       = "Diagnostica y repara problemas comunes de Windows"
                TitleUpdates    = "Windows Update"
                SubUpdates      = "Busca, instala, pausa o reanuda actualizaciones"
                TitleAbout      = "Acerca de WinToolerV1"
                SubAbout        = "Informacion de version y creditos"
                BtnSelectAll     = "Selec. Todo";   BtnDeselectAll  = "Ninguno"
                BtnInstall       = "Instalar Seleccionados"
                BtnInstallCancel = "Cancelar"
                BtnRefreshUn     = "Actualizar Lista"
                BtnUninstall     = "Desinstalar Seleccionados"
                BtnCheckAll      = "Selec. Todo";   BtnUncheckAll   = "Ninguno"
                BtnApplyTweaks   = "Aplicar Ajustes Seleccionados"
                BtnUndoTweaks    = "Deshacer Seleccionados"
                BtnSvcDisable    = "Deshabilitar Selec."
                BtnSvcManual     = "Poner Manual"
                BtnSvcEnable     = "Reactivar"
                BtnRunUpdates    = "Buscar e Instalar"
                BtnPauseUpdates  = "Pausar 7 Dias"
                BtnResumeUpdates = "Reanudar Updates"
                BtnOpenLog       = "Abrir Archivo de Log"
                TplNone          = "Ninguno";        TplStandard = "Estandar"
                TplMinimal       = "Minimo";         TplHeavy    = "Completo"
                LangToggleLabel  = "Idioma"
                DiskCleanTitle   = "Limpieza de Disco"
                DiskCleanMsg     = "Ejecutando limpieza de disco en segundo plano..."
                DiskCleanDone    = "Limpieza de disco finalizada."
                TweaksDone       = "Listo! Aplicados"
                TweaksOf         = "de"
                TweaksDiskClean  = "tweaks. Iniciando limpieza de disco..."
                SearchPlaceholder = "Buscar..."
                StatusReady      = "Listo"
                AboutVersion     = "Version";        AboutLicense = "Licencia"
                AboutInspired    = "Inspirado en";   AboutLog     = "Archivo de log"
            }
        } else {
            return @{
                NavApps       = "Applications"
                NavInstall    = "Install Apps";     NavUninstall   = "Uninstall"
                NavAppUpdates = "App Updates";      NavTweaks      = "Tweaks"
                NavServices   = "Services";         NavRepair      = "Repair"
                NavUpdates    = "Windows Update";   NavAbout       = "About"
                TitleApps       = "Applications"
                SubApps         = "Install, uninstall or update apps via winget"
                ModeLblInstall   = "Install"
                ModeLblUninstall = "Uninstall"
                TitleInstall    = "Install Applications"
                SubInstall      = "Select apps to install via winget"
                TitleUninstall  = "Uninstall Applications"
                SubUninstall    = "Remove winget-managed apps from your system"
                TitleAppUpdates = "App Updates"
                SubAppUpdates   = "Apps with updates available - scanned at startup"
                TitleTweaks     = "System Tweaks"
                SubTweaks       = "Apply performance, privacy and UI optimisations"
                TitleServices   = "Windows Services"
                SubServices     = "Manage and disable unnecessary background services"
                TitleRepair     = "Repair and Maintenance"
                SubRepair       = "Diagnose and fix common Windows issues"
                TitleUpdates    = "Windows Updates"
                SubUpdates      = "Check, install, pause or resume Windows updates"
                TitleAbout      = "About WinToolerV1"
                SubAbout        = "Version information and credits"
                BtnSelectAll     = "Select All";    BtnDeselectAll  = "None"
                BtnInstall       = "Install Selected"
                BtnInstallCancel = "Cancel"
                BtnRefreshUn     = "Refresh List"
                BtnUninstall     = "Uninstall Selected"
                BtnCheckAll      = "Select All";    BtnUncheckAll   = "None"
                BtnApplyTweaks   = "Apply Selected Tweaks"
                BtnUndoTweaks    = "Undo Selected"
                BtnSvcDisable    = "Disable Selected"
                BtnSvcManual     = "Set Manual"
                BtnSvcEnable     = "Re-Enable"
                BtnRunUpdates    = "Check and Install"
                BtnPauseUpdates  = "Pause 7 Days"
                BtnResumeUpdates = "Resume Updates"
                BtnOpenLog       = "Open Log File"
                TplNone          = "None";           TplStandard = "Standard"
                TplMinimal       = "Minimal";        TplHeavy    = "Heavy"
                LangToggleLabel  = "Language"
                DiskCleanTitle   = "Disk Cleanup"
                DiskCleanMsg     = "Running disk cleanup in the background..."
                DiskCleanDone    = "Disk cleanup finished."
                TweaksDone       = "Done! Applied"
                TweaksOf         = "of"
                TweaksDiskClean  = "tweaks. Running disk cleanup..."
                SearchPlaceholder = "Search..."
                StatusReady      = "Ready"
                AboutVersion     = "Version";        AboutLicense = "License"
                AboutInspired    = "Inspired by";    AboutLog     = "Log file"
            }
        }
    }

    $script:applyLanguage = { param([string]$newLang)
        # Pin the language globally so nothing can reset it
        $script:lang        = $newLang
        $global:UILanguage  = $newLang
        $S                  = script:Build-StringTable $newLang
        $global:UIStrings   = $S

        # -- Button / control labels --
        $map = @{
            "BtnSelectAll"     = "BtnSelectAll";   "BtnDeselectAll"   = "BtnDeselectAll"
            "BtnInstall"       = "BtnInstall";     "BtnInstallCancel" = "BtnInstallCancel"
            "BtnRefreshUninstall" = "BtnRefreshUn"; "BtnUninstall"    = "BtnUninstall"
            "BtnUncheckAll"    = "BtnUncheckAll";  "BtnApplyTweaks"   = "BtnApplyTweaks"
            "BtnUndoTweaks"    = "BtnUndoTweaks";  "BtnSvcDisable"    = "BtnSvcDisable"
            "BtnSvcManual"     = "BtnSvcManual";   "BtnSvcEnable"     = "BtnSvcEnable"
            "BtnRunUpdates"    = "BtnRunUpdates";  "BtnPauseUpdates"  = "BtnPauseUpdates"
            "BtnResumeUpdates" = "BtnResumeUpdates"; "BtnOpenLog"     = "BtnOpenLog"
            "TplNone"          = "TplNone";        "TplStandard"      = "TplStandard"
            "TplMinimal"       = "TplMinimal";     "TplHeavy"         = "TplHeavy"
        }
        foreach ($ctrlName in $map.Keys) {
            if ($ctrl[$ctrlName]) { $ctrl[$ctrlName].Content = $S[$map[$ctrlName]] }
        }

        # -- Lang label --
        if ($ctrl["LangLabel"]) { $ctrl["LangLabel"].Text = $S["LangToggleLabel"] }

        # -- Toggle button visual state --
        $isES = ($newLang -eq "ES")
        $enBG = if (-not $isES) { "#0067C0" } else { "Transparent" }
        $enFG = if (-not $isES) { "#FFFFFF"  } else { "#3A5570" }
        $esBG = if ($isES)      { "#0067C0" } else { "Transparent" }
        $esFG = if ($isES)      { "#FFFFFF"  } else { "#3A5570" }
        if ($ctrl["BtnLangEN"]) {
            $ctrl["BtnLangEN"].Background = script:Brush $enBG
            $ctrl["BtnLangEN"].Foreground = script:Brush $enFG
        }
        if ($ctrl["BtnLangES"]) {
            $ctrl["BtnLangES"].Background = script:Brush $esBG
            $ctrl["BtnLangES"].Foreground = script:Brush $esFG
        }

        # -- Nav button text (walk each button's inner StackPanel for the label TextBlock) --
        $navLabelMap = @{
            "NavApps"="NavApps"; "NavTweaks"="NavTweaks"
            "NavServices"="NavServices"; "NavRepair"="NavRepair"
            "NavUpdates"="NavUpdates"; "NavAbout"="NavAbout"
        }
        foreach ($n in $navLabelMap.Keys) {
            if (-not $ctrl[$n]) { continue }
            try {
                $sp = $ctrl[$n].Content
                if ($sp -and $sp.GetType().Name -eq "StackPanel") {
                    # Last TextBlock child is the nav label
                    $lbl = $sp.Children | Where-Object { $_.GetType().Name -eq "TextBlock" } | Select-Object -Last 1
                    if ($lbl -and $S.ContainsKey($navLabelMap[$n])) {
                        $lbl.Text = $S[$navLabelMap[$n]]
                    }
                }
            } catch {}
        }

        # -- Page titles map (always kept in sync) --
        $pageTitles["Apps"]      = @($S["TitleApps"],      $S["SubApps"])
        $pageTitles["Tweaks"]    = @($S["TitleTweaks"],    $S["SubTweaks"])
        $pageTitles["Services"]  = @($S["TitleServices"],  $S["SubServices"])
        $pageTitles["Repair"]    = @($S["TitleRepair"],    $S["SubRepair"])
        $pageTitles["Updates"]   = @($S["TitleUpdates"],   $S["SubUpdates"])
        $pageTitles["About"]     = @($S["TitleAbout"],     $S["SubAbout"])

        # -- Mode pill labels --
        if ($ctrl["ModeLblInstall"])   { $ctrl["ModeLblInstall"].Text   = if ($S.ContainsKey("ModeLblInstall"))   { $S["ModeLblInstall"] }   else { "Install"         } }
        if ($ctrl["ModeLblUninstall"]) { $ctrl["ModeLblUninstall"].Text = if ($S.ContainsKey("ModeLblUninstall")) { $S["ModeLblUninstall"] } else { "Uninstall"       } }
        if ($ctrl["ModeLblUpdateAll"]) { $ctrl["ModeLblUpdateAll"].Text = if ($S.ContainsKey("ModeLblUpdateAll")) { $S["ModeLblUpdateAll"] } else { "Update All Apps" } }

        # -- Refresh current page header immediately --
        if ($pageTitles.ContainsKey($script:CurrentPage)) {
            $ctrl["PageTitle"].Text    = $pageTitles[$script:CurrentPage][0]
            $ctrl["PageSubtitle"].Text = $pageTitles[$script:CurrentPage][1]
        }
    }

    # Apply Aero glass effect once window handle is available
    $win.Add_SourceInitialized({
        try {
            $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($win)).Handle
            $enabled = $false
            [AeroGlass]::DwmIsCompositionEnabled([ref]$enabled) | Out-Null
            if ($enabled) {
                # Extend frame across entire client area (-1 = all margins)
                $m = New-Object AeroGlass+MARGINS
                $m.Left = -1; $m.Right = -1; $m.Top = -1; $m.Bottom = -1
                [AeroGlass]::DwmExtendFrameIntoClientArea($hwnd, [ref]$m) | Out-Null
            }
        } catch {}
    })

    $win.Add_Loaded({
        try {
            # Apply startup theme
            & script:Apply-Theme $false

            # Load app icon — use $global:Root set by WinToolerV1.ps1 launcher
            try {
                $iconBase = if ($global:Root) { $global:Root } else { $PSScriptRoot }
                $iconPath = Join-Path $iconBase "WinToolerV1_icon.png"
                if (Test-Path $iconPath) {
                    $iconAbsPath = (Resolve-Path $iconPath).Path
                    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $bmp.BeginInit()
                    $bmp.UriSource        = New-Object System.Uri($iconAbsPath, [System.UriKind]::Absolute)
                    $bmp.DecodePixelWidth = 128
                    $bmp.CacheOption      = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $bmp.EndInit()
                    $bmp.Freeze()
                    if ($ctrl["SidebarIcon"]) { $ctrl["SidebarIcon"].Source = $bmp }
                    if ($ctrl["AboutIcon"])   { $ctrl["AboutIcon"].Source   = $bmp }
                    $winBmp = New-Object System.Windows.Media.Imaging.BitmapImage
                    $winBmp.BeginInit()
                    $winBmp.UriSource        = New-Object System.Uri($iconAbsPath, [System.UriKind]::Absolute)
                    $winBmp.DecodePixelWidth = 32
                    $winBmp.CacheOption      = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $winBmp.EndInit()
                    $winBmp.Freeze()
                    $win.Icon = $winBmp
                }
            } catch { Write-WTLog "Icon load error: $_" "WARN" }

            # Winget status indicator
            if ($global:WingetPath) {
                $ctrl["WingetDot"].Fill    = script:Brush "#00CC6A"
                $ctrl["WingetStatus"].Text = if ($S.ContainsKey("StatusReady")) { $S["StatusReady"] } else { "Ready" }
            } else {
                $ctrl["WingetDot"].Fill    = script:Brush "#FC3E3E"
                $ctrl["WingetStatus"].Text = "not found"
                $ctrl["BtnInstall"].IsEnabled = $false
            }

            # Apply language strings after window is fully loaded
            # Use a one-shot DispatcherTimer so all panels are rendered before we walk them
            $langTimer = New-Object System.Windows.Threading.DispatcherTimer
            $langTimer.Interval = [TimeSpan]::FromMilliseconds(50)
            $langTimer.Add_Tick({
                $langTimer.Stop()
                try {
                    & $script:applyLanguage $script:lang
                } catch {
                    Write-WTLog "Apply-Language error: $($_.Exception.Message) at $($_.InvocationInfo.ScriptLineNumber)" "ERROR"
                }
            }.GetNewClosure())
            $langTimer.Start()

        } catch {
            Write-WTLog "Add_Loaded error: $($_.Exception.Message) | Line: $($_.InvocationInfo.ScriptLineNumber)" "ERROR"
        }
    })

    # Open log button
    $ctrl["BtnOpenLog"].Add_Click({
        if (Test-Path $global:LogFile) { Start-Process notepad.exe -ArgumentList $global:LogFile }
    })

    # ----------------------------------------------------------------
    #  IN-APP LANGUAGE TOGGLE  (EN / ES pill in sidebar footer)
    # ----------------------------------------------------------------
    $ctrl["BtnLangEN"].Add_Click({
        if ($script:lang -ne "EN") {
            & $script:applyLanguage "EN"
            Write-WTLog "Language switched to EN"
        }
    })
    $ctrl["BtnLangES"].Add_Click({
        if ($script:lang -ne "ES") {
            & $script:applyLanguage "ES"
            Write-WTLog "Language switched to ES"
        }
    })

    # ================================================================
    #  BUILD INSTALL TAB
    # ================================================================
    $script:CBMap    = @{}
    $script:RowMap   = @{}
    $script:BadgeMap = @{}
    $script:CurCat   = "All"
    $transpBG        = [Windows.Media.Brushes]::Transparent

    $refreshCount = {
        $n = ($script:CBMap.Values | Where-Object { $_.IsChecked }).Count
        $ctrl["SelCountTxt"].Text     = "$n selected"
        $ctrl["BtnInstall"].IsEnabled = ($n -gt 0) -and ($null -ne $global:WingetPath)
        $ctrl["BtnInstall"].Content   = if ($n -gt 1) { "Install $n Apps" } elseif ($n -eq 1) { "Install 1 App" } else { "Install Selected" }
    }

    $applyInstallFilter = {
        $txt = $ctrl["InstallSearch"].Text.Trim()
        foreach ($id in $script:RowMap.Keys) {
            $app   = $global:AppCatalog | Where-Object { $_.Id -eq $id }
            $catOk = ($script:CurCat -eq "All") -or ($app.Category -eq $script:CurCat)
            $txtOk = ($txt -eq "") -or ($app.Name -like "*$txt*") -or ($app.Description -like "*$txt*")
            $script:RowMap[$id].Visibility = if ($catOk -and $txtOk) { "Visible" } else { "Collapsed" }
        }
    }
    $ctrl["InstallSearch"].Add_TextChanged({ & $applyInstallFilter })

    # Category buttons
    $catList   = @("All") + ($global:AppCatalog | Select-Object -ExpandProperty Category | Sort-Object -Unique)
    $catBtnMap = @{}
    $catColors = @{
        "All"            = "#0078D4"
        "Browsers"       = "#E67E22"; "Communications" = "#9B59B6"
        "Development"    = "#3498DB"; "Document"       = "#E74C3C"
        "Gaming"         = "#1ABC9C"; "Media"          = "#E83030"
        "Network"        = "#0097A7"; "Productivity"   = "#F39C12"
        "Security"       = "#D32F2F"; "Utilities"      = "#27AE60"
    }

    foreach ($cat in $catList) {
        $catCopy = $cat
        $isAll   = ($cat -eq "All")
        $count   = if ($isAll) { $global:AppCatalog.Count } else { ($global:AppCatalog | Where-Object { $_.Category -eq $cat }).Count }
        $cColor  = if ($catColors.ContainsKey($cat)) { $catColors[$cat] } else { "#888888" }
        $cRgb    = [Windows.Media.ColorConverter]::ConvertFromString($cColor)

        $catBd = New-Object Windows.Controls.Border
        $catBd.CornerRadius = New-Object Windows.CornerRadius(7)
        $catBd.Padding      = New-Object Windows.Thickness(10,7,10,7)
        $catBd.Margin       = New-Object Windows.Thickness(0,1,0,1)
        $catBd.Cursor       = [System.Windows.Input.Cursors]::Hand
        $catBd.Tag          = $cat

        $sp = New-Object Windows.Controls.StackPanel
        $sp.Orientation = "Horizontal"

        $dot = New-Object Windows.Shapes.Ellipse
        $dot.Width  = 6; $dot.Height = 6
        $dot.Fill   = New-Object Windows.Media.SolidColorBrush($cRgb)
        $dot.VerticalAlignment = "Center"
        $dot.Margin = New-Object Windows.Thickness(0,0,7,0)

        $lbl = New-Object Windows.Controls.TextBlock
        $lbl.Text = $cat; $lbl.FontSize = 12

        $cnt = New-Object Windows.Controls.TextBlock
        $cnt.Text = "  $count"; $cnt.FontSize = 10
        $cnt.VerticalAlignment = "Bottom"
        $cnt.Margin = New-Object Windows.Thickness(2,0,0,1)
        $cnt.Foreground = script:Brush $script:T.Text4

        $sp.Children.Add($dot) | Out-Null
        $sp.Children.Add($lbl) | Out-Null
        $sp.Children.Add($cnt) | Out-Null
        $catBd.Child = $sp

        if ($isAll) {
            $catBd.Background = script:Brush $script:T.NavActBG
            $lbl.Foreground   = script:Brush $script:T.NavActFG
            $lbl.FontWeight   = [Windows.FontWeights]::SemiBold
        } else {
            $catBd.Background = $transpBG
            $lbl.Foreground   = script:Brush $script:T.Text3
        }

        $catBtnMap[$cat] = @{ Border=$catBd; Label=$lbl }

        $catBd.Add_MouseLeftButtonUp({
            param($s,$e)
            $clicked = $s.Tag
            foreach ($k in $catBtnMap.Keys) {
                $catBtnMap[$k].Border.Background = $transpBG
                $catBtnMap[$k].Label.Foreground  = script:Brush $script:T.Text3
                $catBtnMap[$k].Label.FontWeight  = [Windows.FontWeights]::Normal
            }
            $catBtnMap[$clicked].Border.Background = script:Brush $script:T.NavActBG
            $catBtnMap[$clicked].Label.Foreground  = script:Brush $script:T.NavActFG
            $catBtnMap[$clicked].Label.FontWeight  = [Windows.FontWeights]::SemiBold
            $script:CurCat = $clicked
            & $applyInstallFilter
        })
        $ctrl["CatPanel"].Children.Add($catBd) | Out-Null
    }

    # App rows
    $lastCat = ""
    foreach ($app in ($global:AppCatalog | Sort-Object Category, Name)) {
        if ($app.Category -ne $lastCat) {
            if ($lastCat -ne "") {
                $sp = New-Object Windows.Controls.Border; $sp.Height = 6
                $ctrl["AppPanel"].Children.Add($sp) | Out-Null
            }
            $acColor = if ($catColors.ContainsKey($app.Category)) { $catColors[$app.Category] } else { "#0078D4" }
            $acRgb   = [Windows.Media.ColorConverter]::ConvertFromString($acColor)

            $dg = New-Object Windows.Controls.Grid
            $dg.Margin = New-Object Windows.Thickness(0,2,0,8)
            $dg.Tag    = $app.Category
            $dc1 = New-Object Windows.Controls.ColumnDefinition; $dc1.Width = [Windows.GridLength]::Auto
            $dc2 = New-Object Windows.Controls.ColumnDefinition
            $dg.ColumnDefinitions.Add($dc1); $dg.ColumnDefinitions.Add($dc2)

            $pill = New-Object Windows.Controls.Border
            $pill.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(30,$acRgb.R,$acRgb.G,$acRgb.B))
            $pill.CornerRadius = New-Object Windows.CornerRadius(4)
            $pill.Padding      = New-Object Windows.Thickness(10,3,10,3)
            $pillTb = New-Object Windows.Controls.TextBlock
            $pillTb.Text = $app.Category.ToUpper(); $pillTb.FontSize = 10; $pillTb.FontWeight = [Windows.FontWeights]::Bold
            $pillTb.Foreground = New-Object Windows.Media.SolidColorBrush($acRgb)
            $pill.Child = $pillTb
            [Windows.Controls.Grid]::SetColumn($pill, 0); $dg.Children.Add($pill) | Out-Null

            $ln = New-Object Windows.Controls.Border
            $ln.Background = script:Brush $script:T.Border1
            $ln.Height = 1; $ln.Margin = New-Object Windows.Thickness(10,0,0,0)
            $ln.VerticalAlignment = "Center"
            [Windows.Controls.Grid]::SetColumn($ln, 1); $dg.Children.Add($ln) | Out-Null

            $ctrl["AppPanel"].Children.Add($dg) | Out-Null
            $lastCat = $app.Category
        }

        $row = New-Object Windows.Controls.Border
        $row.Background   = $transpBG
        $row.CornerRadius = New-Object Windows.CornerRadius(6)
        $row.Padding      = New-Object Windows.Thickness(10,6,10,6)
        $row.Margin       = New-Object Windows.Thickness(0,1,0,1)
        $row.Cursor       = [System.Windows.Input.Cursors]::Hand
        $row.Tag          = $app.Id

        $rg  = New-Object Windows.Controls.Grid
        $rc1 = New-Object Windows.Controls.ColumnDefinition; $rc1.Width = [Windows.GridLength]::Auto
        $rc2 = New-Object Windows.Controls.ColumnDefinition
        $rc3 = New-Object Windows.Controls.ColumnDefinition; $rc3.Width = [Windows.GridLength]::Auto
        $rg.ColumnDefinitions.Add($rc1)
        $rg.ColumnDefinitions.Add($rc2)
        $rg.ColumnDefinitions.Add($rc3)

        $cb = New-Object Windows.Controls.CheckBox
        $cb.IsChecked = $false; $cb.VerticalAlignment = "Center"; $cb.Tag = $app.Id
        $cb.Margin = New-Object Windows.Thickness(0,0,10,0)
        [Windows.Controls.Grid]::SetColumn($cb, 0); $rg.Children.Add($cb) | Out-Null

        $txSp = New-Object Windows.Controls.StackPanel; $txSp.VerticalAlignment = "Center"
        $nm = New-Object Windows.Controls.TextBlock; $nm.Text = $app.Name; $nm.FontSize = 12
        $nm.FontWeight = [Windows.FontWeights]::SemiBold; $nm.Foreground = script:Brush $script:T.Text1
        $ds = New-Object Windows.Controls.TextBlock; $ds.FontSize = 10
        $ds.Foreground = script:Brush $script:T.Text3
        $ds.Text = "$($app.Description)  ·  $($app.Id)"
        $ds.Margin = New-Object Windows.Thickness(0,1,0,0)
        $txSp.Children.Add($nm) | Out-Null; $txSp.Children.Add($ds) | Out-Null
        [Windows.Controls.Grid]::SetColumn($txSp, 1); $rg.Children.Add($txSp) | Out-Null

        $stBd = New-Object Windows.Controls.Border
        $stBd.CornerRadius = New-Object Windows.CornerRadius(12)
        $stBd.Padding = New-Object Windows.Thickness(10,3,10,3)
        $stBd.VerticalAlignment = "Center"; $stBd.Margin = New-Object Windows.Thickness(12,0,0,0)
        $stBd.Visibility = "Collapsed"
        $stTb = New-Object Windows.Controls.TextBlock; $stTb.FontSize = 10; $stTb.FontWeight = [Windows.FontWeights]::SemiBold
        $stBd.Child = $stTb
        [Windows.Controls.Grid]::SetColumn($stBd, 2); $rg.Children.Add($stBd) | Out-Null
        $row.Child = $rg

        $ctrl["AppPanel"].Children.Add($row) | Out-Null
        $script:CBMap[$app.Id]    = $cb
        $script:RowMap[$app.Id]   = $row
        $script:BadgeMap[$app.Id] = $stBd

        $cb.Add_Checked({   & $refreshCount })
        $cb.Add_Unchecked({ & $refreshCount })

        $row.Add_MouseEnter({
            param($s,$e)
            if ($s.Background -eq $transpBG -or $null -eq $s.Background -or $s.Background.Color.A -eq 0) {
                $s.Background = script:Brush $script:T.Surface2
            }
        })
        $row.Add_MouseLeave({
            param($s,$e)
            $id = $s.Tag
            if ($script:CBMap[$id].IsChecked -ne $true) { $s.Background = $transpBG }
        })
        $row.Add_MouseLeftButtonUp({
            param($s,$e)
            $id = $s.Tag
            $script:CBMap[$id].IsChecked = -not $script:CBMap[$id].IsChecked
        })
    }

    $ctrl["BtnSelectAll"].Add_Click({
        foreach ($id in $script:CBMap.Keys) {
            if ($script:RowMap[$id].Visibility -eq "Visible") { $script:CBMap[$id].IsChecked = $true }
        }
        & $refreshCount
    })
    $ctrl["BtnDeselectAll"].Add_Click({
        foreach ($cb in $script:CBMap.Values) { $cb.IsChecked = $false }
        & $refreshCount
    })

    # ── Background winget ID validator ──────────────────────────────────────
    # Validates all 111 app IDs via winget search --exact.
    # Uses a throttled pool of max 8 concurrent Start-Jobs so winget isn't
    # overwhelmed. Badges update live: green ✓ OK / red ⚠ Not found.
    # Runs once per session on first visit to the Apps page.
    $script:ValidationDone = $false
    $script:okCount        = 0
    $script:failCount      = 0

    $script:RunValidation = {
        if ($script:ValidationDone -or -not $global:WingetPath) { return }
        $script:ValidationDone = $true
        $script:okCount   = 0
        $script:failCount = 0

        $pending = [System.Collections.Queue]::new()
        foreach ($id in ($global:AppCatalog | Select-Object -ExpandProperty Id)) {
            $pending.Enqueue($id)
        }
        $script:valTotal   = $pending.Count
        $script:valWinget  = $global:WingetPath
        $script:valMaxConc = 8
        $script:valRunning = [System.Collections.Generic.List[hashtable]]::new()
        $script:valPending = $pending

        & $script:setStatus "Validating $($script:valTotal) app IDs via winget..." "#0067C0"
        Write-WTLog "App validation started: $($script:valTotal) IDs, pool=$($script:valMaxConc)"

        # Seed initial pool
        while ($script:valRunning.Count -lt $script:valMaxConc -and $script:valPending.Count -gt 0) {
            $idCopy = $script:valPending.Dequeue()
            $job = Start-Job -ScriptBlock {
                param($wp, $pkgId)
                $null = & $wp search --id $pkgId --exact --source winget --disable-interactivity 2>&1
                return @{ Id = $pkgId; Code = $LASTEXITCODE }
            } -ArgumentList $script:valWinget, $idCopy
            $script:valRunning.Add(@{ Job = $job; Id = $idCopy })
        }

        $script:valTimer = New-Object System.Windows.Threading.DispatcherTimer
        $script:valTimer.Interval = [TimeSpan]::FromMilliseconds(800)
        $script:valTimer.Add_Tick({
            # Harvest finished jobs
            $keep = [System.Collections.Generic.List[hashtable]]::new()
            foreach ($entry in $script:valRunning) {
                $j = $entry.Job
                if ($j.State -eq "Completed" -or $j.State -eq "Failed") {
                    try {
                        $r     = Receive-Job $j -ErrorAction Stop
                        $badge = $script:BadgeMap[$r.Id]
                        if ($badge) {
                            $tb = $badge.Child
                            if ($r.Code -eq 0) {
                                $badge.Background      = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(35,0,180,80))
                                $badge.BorderBrush     = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(100,0,160,70))
                                $badge.BorderThickness = New-Object Windows.Thickness(1)
                                $tb.Foreground         = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(0,130,55))
                                $tb.Text               = "$([char]0x2713) OK"
                                $script:okCount++
                            } else {
                                $badge.Background      = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(35,210,50,50))
                                $badge.BorderBrush     = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(100,200,40,40))
                                $badge.BorderThickness = New-Object Windows.Thickness(1)
                                $tb.Foreground         = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(190,35,35))
                                $tb.Text               = "$([char]0x26A0) Not found"
                                $script:failCount++
                            }
                            $badge.Visibility = "Visible"
                        }
                    } catch {}
                    Remove-Job $j -Force -ErrorAction SilentlyContinue
                } else {
                    $keep.Add($entry)
                }
            }
            $script:valRunning.Clear(); foreach ($e in $keep) { $script:valRunning.Add($e) }

            # Fill empty slots from queue
            while ($script:valRunning.Count -lt $script:valMaxConc -and $script:valPending.Count -gt 0) {
                $idCopy = $script:valPending.Dequeue()
                $job = Start-Job -ScriptBlock {
                    param($wp, $pkgId)
                    $null = & $wp search --id $pkgId --exact --source winget --disable-interactivity 2>&1
                    return @{ Id = $pkgId; Code = $LASTEXITCODE }
                } -ArgumentList $script:valWinget, $idCopy
                $script:valRunning.Add(@{ Job = $job; Id = $idCopy })
            }

            $checked = $script:valTotal - $script:valPending.Count - $script:valRunning.Count
            if ($script:valRunning.Count -gt 0 -or $script:valPending.Count -gt 0) {
                & $script:setStatus "Validating: $checked / $($script:valTotal)  ($($script:valRunning.Count) active)..." "#0067C0"
            } else {
                $script:valTimer.Stop()
                $ok   = $script:okCount
                $fail = $script:failCount
                $msg  = if ($fail -eq 0) { "All $ok apps verified OK in winget" } else { "$ok apps OK  |  $fail not found in winget" }
                $col  = if ($fail -eq 0) { "#00AA50" } else { "#CC6000" }
                & $script:setStatus $msg $col
                Write-WTLog "App validation done: ok=$ok notfound=$fail"
            }
        })
        $script:valTimer.Start()
    }

    # Trigger validation when Apps nav is clicked (first time only)
    $ctrl["NavApps"].Add_Click({ & $script:RunValidation })

    # Install button
    $ctrl["BtnInstall"].Add_Click({
        $toInstall = $global:AppCatalog | Where-Object { $script:CBMap[$_.Id].IsChecked -eq $true }
        $total = @($toInstall).Count
        if ($total -eq 0) { return }

        foreach ($c in $script:CBMap.Values) { $c.IsEnabled = $false }
        $ctrl["BtnSelectAll"].IsEnabled = $false; $ctrl["BtnDeselectAll"].IsEnabled = $false
        $ctrl["BtnInstall"].IsEnabled   = $false; $ctrl["BtnInstallCancel"].Visibility = "Visible"
        $ctrl["InstallProgressPanel"].Visibility = "Visible"
        $ctrl["InstallProgBar"].Value = 0
        $ok = 0; $skip = 0; $fail = 0; $i = 0

        Write-Host ""
        Write-Host "  --[ Installing $total Apps ]" -ForegroundColor Cyan
        Write-Host ""

        foreach ($app in $toInstall) {
            $i++
            $pct = [int](($i - 1) / $total * 100)
            $ctrl["InstallProgBar"].Value  = $pct
            $ctrl["InstallProgCount"].Text = "$i of $total"
            $ctrl["InstallProgLabel"].Text = "Installing $($app.Name)..."
            $win.Dispatcher.Invoke([action]{}, "Render")

            # CLI progress bar
            $barWidth = 28
            $filled   = [int]($pct / 100 * $barWidth)
            $bar      = ("#" * $filled).PadRight($barWidth)
            Write-Host ("  [{0}] {1,3}%  {2}" -f $bar, $pct, $app.Name) -ForegroundColor DarkCyan
            $badgeTb = $badge.Child
            $badge.Visibility = "Visible"
            $badgeTb.Text = "Installing..."
            $badge.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(30,60,100))
            $badgeTb.Foreground = [Windows.Media.Brushes]::White

            # Determine preferred scope from apps.json, default machine
            $prefScope = if ($app.PSObject.Properties["Scope"] -and $app.Scope) { $app.Scope } else { "machine" }
            $altScope  = if ($prefScope -eq "machine") { "user" } else { "machine" }

            # Common flags reused across all attempts
            $commonFlags = @("--silent","--locale","en-US","--accept-package-agreements","--accept-source-agreements","--disable-interactivity")

            # ── Attempt 1: preferred scope ────────────────────────────────────────
            $out  = & $global:WingetPath install --id $app.Id --scope $prefScope @commonFlags 2>&1
            $code = $LASTEXITCODE

            # ── Attempt 2: flip scope (scope conflict or CDN failure on machine) ──
            if ($code -ne 0 -and $code -ne -1978335189) {
                $out  = & $global:WingetPath install --id $app.Id --scope $altScope @commonFlags 2>&1
                $code = $LASTEXITCODE
            }

            # ── Attempt 3: no scope flag at all (let winget decide) ───────────────
            if ($code -ne 0 -and $code -ne -1978335189) {
                $out  = & $global:WingetPath install --id $app.Id @commonFlags 2>&1
                $code = $LASTEXITCODE
            }

            # ── Attempt 4: preferred scope + ignore hash ──────────────────────────
            # Covers: -1978335212 (hash mismatch), 0x80190194 (HTTP 404 on CDN)
            if ($code -ne 0 -and $code -ne -1978335189) {
                $out  = & $global:WingetPath install --id $app.Id --scope $prefScope @commonFlags --ignore-security-hash 2>&1
                $code = $LASTEXITCODE
            }

            # ── Attempt 5: alt scope + ignore hash ───────────────────────────────
            if ($code -ne 0 -and $code -ne -1978335189) {
                $out  = & $global:WingetPath install --id $app.Id --scope $altScope @commonFlags --ignore-security-hash 2>&1
                $code = $LASTEXITCODE
            }

            # ── Attempt 6: no scope + ignore hash (broadest fallback) ─────────────
            if ($code -ne 0 -and $code -ne -1978335189) {
                $out  = & $global:WingetPath install --id $app.Id @commonFlags --ignore-security-hash 2>&1
                $code = $LASTEXITCODE
            }

            Write-WTLog "winget $($app.Id) [scope=$prefScope] final => exit $code"

            $barFull = ("#" * 28)
            if ($code -eq 0) {
                Write-Host ("  [{0}] 100%  {1}  >> Installed" -f $barFull, $app.Name) -ForegroundColor Green
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(10,50,25))
                $badgeTb.Text       = "Installed"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(0,204,106))
                $ok++
            } elseif ($code -eq -1978335189) {
                Write-Host ("  [{0}] 100%  {1}  >> Already present" -f $barFull, $app.Name) -ForegroundColor DarkYellow
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(30,25,10))
                $badgeTb.Text       = "Already present"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(180,140,0))
                $skip++
            } elseif ($code -eq -1978335216) {
                Write-Host ("  [{0}]  ERR  {1}  >> Not found in winget" -f $barFull, $app.Name) -ForegroundColor Red
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(50,10,10))
                $badgeTb.Text       = "Not found"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(252,62,62))
                $fail++
            } elseif ($code -eq -2145844844 -or $code -eq -1978335230 -or $code -eq -1978335212) {
                $hexCode = "0x{0:X8}" -f [uint32]$code
                Write-Host ("  [{0}]  ERR  {1}  >> Download failed ({2})" -f $barFull, $app.Name, $hexCode) -ForegroundColor Red
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(50,10,10))
                $badgeTb.Text       = "Download failed"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(252,62,62))
                $fail++
            } else {
                $hexCode = "0x{0:X8}" -f [uint32]$code
                Write-Host ("  [{0}]  ERR  {1}  >> Failed ({2})" -f $barFull, $app.Name, $hexCode) -ForegroundColor Red
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(50,10,10))
                $badgeTb.Text       = "Failed $hexCode"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(252,62,62))
                $fail++
            }
            $win.Dispatcher.Invoke([action]{}, "Render")
        }

        $ctrl["InstallProgBar"].Value  = 100
        $ctrl["InstallProgCount"].Text = "$total of $total"
        $ctrl["InstallProgLabel"].Text = "Done!  Installed: $ok   Already present: $skip   Failed: $fail"
        $ctrl["BtnInstallCancel"].Visibility = "Collapsed"
        foreach ($c in $script:CBMap.Values) { $c.IsEnabled = $true }
        $ctrl["BtnSelectAll"].IsEnabled   = $true
        $ctrl["BtnDeselectAll"].IsEnabled = $true
        $ctrl["BtnInstall"].IsEnabled     = $true
        $ctrl["BtnInstall"].Content       = "Install Again"

        Write-Host ""
        Write-Host "  Install complete: OK=$ok  Skip=$skip  Fail=$fail" -ForegroundColor Cyan
        Write-WTLog "Install complete: ok=$ok skip=$skip fail=$fail"
    })

    # ================================================================
    #  BUILD UNINSTALL TAB
    # ================================================================
    $script:UninstallMap = @{}  # id -> @{CB, Name}

    # Cached full uninstall list — fetched once per nav/refresh, never on keystrokes
    $script:UninstallCache = @()

    function script:Fetch-UninstallData {
        $script:UninstallCache = @()
        if (-not $global:WingetPath) { return }
        $ctrl["UninstallCount"].Text = "Loading..."
        $win.Dispatcher.Invoke([action]{}, "Render")
        Write-Host "  [Uninstall] Querying winget list..." -ForegroundColor DarkGray
        $raw = & $global:WingetPath list --disable-interactivity 2>&1
        $inTable = $false
        foreach ($line in $raw) {
            if ($line -match 'Name\s+Id\s+Version') { $inTable = $true; continue }
            if (-not $inTable) { continue }
            if ($line -match '^[-\s]+$' -or $line -notmatch '\S') { continue }
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 2) {
                $nm = $parts[0].Trim(); $id = $parts[1].Trim()
                $vr = if ($parts.Count -ge 3) { $parts[2].Trim() } else { "" }
                if ($nm -and $id -and $id -notmatch '^[{<]') {
                    $script:UninstallCache += [pscustomobject]@{ Name=$nm; Id=$id; Version=$vr }
                }
            }
        }
    }

    function script:Build-UninstallList {
        # Filter cached data only — never calls winget
        $ctrl["UninstallPanel"].Children.Clear()
        $script:UninstallMap = @{}
        if (-not $global:WingetPath) {
            $tb = New-Object Windows.Controls.TextBlock
            $tb.Text = "winget not available."; $tb.Foreground = script:Brush "#FC3E3E"
            $ctrl["UninstallPanel"].Children.Add($tb) | Out-Null
            return
        }
        $searchTxt = $ctrl["InstallSearch"].Text.Trim()
        $filtered  = if ($searchTxt) {
            $script:UninstallCache | Where-Object { $_.Name -like "*$searchTxt*" -or $_.Id -like "*$searchTxt*" }
        } else { $script:UninstallCache }
        $ctrl["UninstallCount"].Text = "$($filtered.Count) apps installed"
        foreach ($entry in ($filtered | Sort-Object Name)) {
            $row = New-Object Windows.Controls.Border
            $row.Background      = script:Brush $script:T.CardBG
            $row.CornerRadius    = New-Object Windows.CornerRadius(8)
            $row.Padding         = New-Object Windows.Thickness(14,10,14,10)
            $row.Margin          = New-Object Windows.Thickness(0,0,0,4)
            $row.BorderBrush     = script:Brush $script:T.CardBorder
            $row.BorderThickness = New-Object Windows.Thickness(1)
            $rg  = New-Object Windows.Controls.Grid
            $rc1 = New-Object Windows.Controls.ColumnDefinition; $rc1.Width = [Windows.GridLength]::Auto
            $rc2 = New-Object Windows.Controls.ColumnDefinition
            $rc3 = New-Object Windows.Controls.ColumnDefinition; $rc3.Width = [Windows.GridLength]::Auto
            $rg.ColumnDefinitions.Add($rc1); $rg.ColumnDefinitions.Add($rc2); $rg.ColumnDefinitions.Add($rc3)
            $cb = New-Object Windows.Controls.CheckBox
            $cb.VerticalAlignment = "Center"; $cb.Tag = $entry.Id
            [Windows.Controls.Grid]::SetColumn($cb, 0); $rg.Children.Add($cb) | Out-Null
            $txSp = New-Object Windows.Controls.StackPanel
            $txSp.Margin = New-Object Windows.Thickness(14,0,0,0); $txSp.VerticalAlignment = "Center"
            $nm2 = New-Object Windows.Controls.TextBlock
            $nm2.Text = $entry.Name; $nm2.FontSize = 13
            $nm2.FontWeight = [Windows.FontWeights]::SemiBold; $nm2.Foreground = script:Brush $script:T.Text1
            $id2 = New-Object Windows.Controls.TextBlock
            $id2.Text = $entry.Id; $id2.FontSize = 10; $id2.Foreground = script:Brush $script:T.Text4
            $txSp.Children.Add($nm2) | Out-Null; $txSp.Children.Add($id2) | Out-Null
            [Windows.Controls.Grid]::SetColumn($txSp, 1); $rg.Children.Add($txSp) | Out-Null
            $verTb = New-Object Windows.Controls.TextBlock
            $verTb.Text = $entry.Version; $verTb.FontSize = 11
            $verTb.Foreground = script:Brush $script:T.Text3; $verTb.VerticalAlignment = "Center"
            [Windows.Controls.Grid]::SetColumn($verTb, 2); $rg.Children.Add($verTb) | Out-Null
            $row.Child = $rg
            $ctrl["UninstallPanel"].Children.Add($row) | Out-Null
            $script:UninstallMap[$entry.Id] = @{ CB=$cb; Name=$entry.Name }
            $cb.Add_Checked({
                $n = ($script:UninstallMap.Values | Where-Object { $_.CB.IsChecked }).Count
                $ctrl["UninstallSelTxt"].Text   = "$n selected"
                $ctrl["BtnUninstall"].IsEnabled = ($n -gt 0)
            })
            $cb.Add_Unchecked({
                $n = ($script:UninstallMap.Values | Where-Object { $_.CB.IsChecked }).Count
                $ctrl["UninstallSelTxt"].Text   = "$n selected"
                $ctrl["BtnUninstall"].IsEnabled = ($n -gt 0)
            })
        }
    }

    # Nav + Refresh: fetch from winget THEN render
    # NavUninstall/NavAppUpdates removed - mode switching now handled by $switchAppsMode pills
    # (kept as comment so old log references don't confuse)
    $ctrl["BtnRefreshUninstall"].Add_Click({ & script:Fetch-UninstallData; & script:Build-UninstallList })
    # Search box: filter cached data only — no winget call
    # Search shared across all modes - InstallSearch.Add_TextChanged already handles install mode above
    # For uninstall mode, wire into the same search box
    $ctrl["InstallSearch"].Add_TextChanged({
        if ($script:AppsMode -eq "Uninstall") { & script:Build-UninstallList }
    })

    $ctrl["BtnUninstall"].Add_Click({
        $toRemove = @($script:UninstallMap.GetEnumerator() | Where-Object { $_.Value.CB.IsChecked })
        $total = $toRemove.Count
        if ($total -eq 0) { return }
        $ok = 0; $fail = 0; $i = 0
        Write-Host ""
        Write-Host "  --[ Uninstalling $total Apps ]" -ForegroundColor Cyan
        Write-Host ""
        foreach ($kv in $toRemove) {
            $i++
            $id   = $kv.Key
            $name = $kv.Value.Name
            $pct  = [int](($i - 1) / $total * 100)
            $barWidth = 28
            $filled   = [int]($pct / 100 * $barWidth)
            $bar      = ("#" * $filled).PadRight($barWidth)
            Write-Host ("  [{0}] {1,3}%  {2}" -f $bar, $pct, $name) -ForegroundColor DarkCyan

            $out  = & $global:WingetPath uninstall --id $id --silent --accept-source-agreements --disable-interactivity 2>&1
            $code = $LASTEXITCODE
            Write-WTLog "winget uninstall $id => exit $code"

            $barFull = ("#" * 28)
            if ($code -eq 0) {
                Write-Host ("  [{0}] 100%  {1}  >> Removed" -f $barFull, $name) -ForegroundColor Green
                $ok++
            } else {
                $hexCode = "0x{0:X8}" -f [uint32]$code
                Write-Host ("  [{0}]  ERR  {1}  >> Failed ({2})" -f $barFull, $name, $hexCode) -ForegroundColor Red
                $fail++
            }
        }
        Write-Host ""
        Write-Host ("  Uninstall complete: OK={0}  Fail={1}" -f $ok, $fail) -ForegroundColor Cyan
        Write-WTLog "Uninstall complete: ok=$ok fail=$fail"
        & script:Fetch-UninstallData
        & script:Build-UninstallList
    })

    # ================================================================
    #  BUILD APP UPDATES TAB
    # ================================================================
    # ================================================================
    #  BUILD TWEAKS TAB
    # ================================================================
    $script:TweakCBs = @{}

    $riskColors = @{ "Low"="#27AE60"; "Medium"="#FFB900"; "High"="#FC3E3E" }
    $lastTweakCat = ""

    foreach ($tweak in ($global:TweaksCatalog | Sort-Object Category, Name)) {
        if ($tweak.Category -ne $lastTweakCat) {
            if ($lastTweakCat -ne "") {
                $sp2 = New-Object Windows.Controls.Border; $sp2.Height = 10
                $ctrl["TweakPanel"].Children.Add($sp2) | Out-Null
            }
            $catLbl = New-Object Windows.Controls.TextBlock
            $catLbl.Text = $tweak.Category.ToUpper(); $catLbl.FontSize = 10; $catLbl.FontWeight = [Windows.FontWeights]::Bold
            $catLbl.Foreground = script:Brush $script:T.Text3
            $catLbl.Margin = New-Object Windows.Thickness(0,0,0,6)
            $ctrl["TweakPanel"].Children.Add($catLbl) | Out-Null
            $lastTweakCat = $tweak.Category
        }

        $tc = New-Object Windows.Controls.Border
        $tc.Background      = script:Brush $script:T.CardBG
        $tc.CornerRadius    = New-Object Windows.CornerRadius(8)
        $tc.BorderBrush     = script:Brush $script:T.CardBorder
        $tc.BorderThickness = New-Object Windows.Thickness(1)
        $tc.Padding         = New-Object Windows.Thickness(14,11,14,11)
        $tc.Margin          = New-Object Windows.Thickness(0,0,0,5)
        $tc.Cursor          = [System.Windows.Input.Cursors]::Hand

        $tg  = New-Object Windows.Controls.Grid
        $tc1 = New-Object Windows.Controls.ColumnDefinition; $tc1.Width = [Windows.GridLength]::Auto
        $tc2 = New-Object Windows.Controls.ColumnDefinition
        $tc3 = New-Object Windows.Controls.ColumnDefinition; $tc3.Width = [Windows.GridLength]::Auto
        $tg.ColumnDefinitions.Add($tc1); $tg.ColumnDefinitions.Add($tc2); $tg.ColumnDefinitions.Add($tc3)

        $tcb = New-Object Windows.Controls.CheckBox
        $tcb.IsChecked = $false; $tcb.VerticalAlignment = "Center"; $tcb.Tag = $tweak.Key
        [Windows.Controls.Grid]::SetColumn($tcb, 0); $tg.Children.Add($tcb) | Out-Null

        $tInfoSp = New-Object Windows.Controls.StackPanel; $tInfoSp.Margin = New-Object Windows.Thickness(12,0,12,0)
        $tNm = New-Object Windows.Controls.TextBlock; $tNm.Text = $tweak.Name; $tNm.FontSize = 13
        $tNm.FontWeight = [Windows.FontWeights]::SemiBold; $tNm.Foreground = script:Brush $script:T.Text1
        $tDs = New-Object Windows.Controls.TextBlock; $tDs.Text = $tweak.Description; $tDs.FontSize = 11
        $tDs.Foreground = script:Brush $script:T.Text3
        $tDs.Margin = New-Object Windows.Thickness(0,3,0,0); $tDs.TextWrapping = "Wrap"
        $tInfoSp.Children.Add($tNm) | Out-Null; $tInfoSp.Children.Add($tDs) | Out-Null
        [Windows.Controls.Grid]::SetColumn($tInfoSp, 1); $tg.Children.Add($tInfoSp) | Out-Null

        $rColor = if ($riskColors.ContainsKey($tweak.Risk)) { $riskColors[$tweak.Risk] } else { "#888888" }
        $rRgb   = [Windows.Media.ColorConverter]::ConvertFromString($rColor)
        $rBd    = New-Object Windows.Controls.Border
        $rBd.Background      = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(20,$rRgb.R,$rRgb.G,$rRgb.B))
        $rBd.BorderBrush     = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(70,$rRgb.R,$rRgb.G,$rRgb.B))
        $rBd.BorderThickness = New-Object Windows.Thickness(1)
        $rBd.CornerRadius    = New-Object Windows.CornerRadius(4)
        $rBd.Padding         = New-Object Windows.Thickness(8,3,8,3); $rBd.VerticalAlignment = "Center"
        $rTb = New-Object Windows.Controls.TextBlock; $rTb.Text = $tweak.Risk; $rTb.FontSize = 10; $rTb.FontWeight = [Windows.FontWeights]::SemiBold
        $rTb.Foreground = New-Object Windows.Media.SolidColorBrush($rRgb)
        $rBd.Child = $rTb
        [Windows.Controls.Grid]::SetColumn($rBd, 2); $tg.Children.Add($rBd) | Out-Null

        $tc.Child = $tg
        $ctrl["TweakPanel"].Children.Add($tc) | Out-Null
        $script:TweakCBs[$tweak.Key] = $tcb

        # Click card to toggle
        $tc.Add_MouseLeftButtonUp({
            param($s,$e)
            $key = $s.Child.Children[0].Tag
            $script:TweakCBs[$key].IsChecked = -not $script:TweakCBs[$key].IsChecked
        })
    }

    $updateTweakCount = {
        $n = ($script:TweakCBs.Values | Where-Object { $_.IsChecked }).Count
        $ctrl["TweakCountLabel"].Text = "$n selected"
    }
    & $updateTweakCount
    foreach ($cb in $script:TweakCBs.Values) {
        $cb.Add_Checked({   & $updateTweakCount })
        $cb.Add_Unchecked({ & $updateTweakCount })
    }

    # Template definitions: key -> list of tweak Keys to enable
    $templates = @{
        "Standard" = @("HighPerfPower","DisableSysMain","ReduceAnimations","DisableTelemetry",
                       "DisableAdID","DisableActivity","BlockTelemetryHosts","DarkMode",
                       "ShowExtensions","RemoveStartAds","CleanTaskbar","DisableBingStart","DisableEdgeBloat")
        "Minimal"  = @("DisableTelemetry","DisableAdID","DisableActivity","RemoveStartAds","CleanTaskbar","DisableBingStart")
        "Heavy"    = @("HighPerfPower","DisableSysMain","DisableSearch","ReduceAnimations","DisableHibernation",
                       "GameMode","DisableTelemetry","DisableAdID","DisableActivity","DisableLocation",
                       "BlockTelemetryHosts","DarkMode","ShowExtensions","ShowHidden","RemoveStartAds",
                       "CleanTaskbar","DisableBingStart","RemoveMSBloat","RemoveXbox","DisableEdgeBloat","DisableOneDrive")
    }

    $applyTemplate = {
        param([string]$tpl)
        foreach ($cb in $script:TweakCBs.Values) { $cb.IsChecked = $false }
        if ($tpl -and $templates.ContainsKey($tpl)) {
            foreach ($key in $templates[$tpl]) {
                if ($script:TweakCBs.ContainsKey($key)) { $script:TweakCBs[$key].IsChecked = $true }
            }
        }
        & $updateTweakCount
    }

    $ctrl["TplNone"].Add_Click({     & $applyTemplate "" })
    $ctrl["TplStandard"].Add_Click({ & $applyTemplate "Standard" })
    $ctrl["TplMinimal"].Add_Click({  & $applyTemplate "Minimal" })
    $ctrl["TplHeavy"].Add_Click({    & $applyTemplate "Heavy" })

    $ctrl["BtnCheckAll"].Add_Click({
        foreach ($cb in $script:TweakCBs.Values) { $cb.IsChecked = $true }
        & $updateTweakCount
    })
    $ctrl["BtnUncheckAll"].Add_Click({
        foreach ($cb in $script:TweakCBs.Values) { $cb.IsChecked = $false }
        & $updateTweakCount
    })

    $ctrl["TweakSearch"].Add_TextChanged({
        $txt = $ctrl["TweakSearch"].Text.Trim()
        foreach ($child in $ctrl["TweakPanel"].Children) {
            if ($child -is [Windows.Controls.Border] -and $child.Child -is [Windows.Controls.Grid]) {
                $key = $child.Child.Children[0].Tag
                if ($key) {
                    $tweak = $global:TweaksCatalog | Where-Object { $_.Key -eq $key }
                    $child.Visibility = if ($txt -eq "" -or $tweak.Name -like "*$txt*" -or $tweak.Description -like "*$txt*") { "Visible" } else { "Collapsed" }
                }
            }
        }
    })

    $ctrl["BtnApplyTweaks"].Add_Click({
        $selected = $global:TweaksCatalog | Where-Object { $script:TweakCBs.ContainsKey($_.Key) -and $script:TweakCBs[$_.Key].IsChecked -eq $true }
        $n = @($selected).Count
        if ($n -eq 0) { & $script:setStatus "No tweaks selected." "#FFB900"; return }
        & $script:setStatus "Applying $n tweaks..."
        Write-Host ""
        Write-Host "  --[ Applying $n Tweaks ]" -ForegroundColor Cyan
        Write-WTLog "Applying $n tweaks..."
        $ok = 0
        foreach ($t in $selected) {
            try {
                & $t.Script
                Write-Host "  OK: $($t.Name)" -ForegroundColor Green
                Write-WTLog "Applied: $($t.Name)"
                $ok++
            } catch {
                Write-Host "  FAIL: $($t.Name) - $_" -ForegroundColor Red
                Write-WTLog "Failed tweak $($t.Name): $_" "ERROR"
            }
        }
        Write-Host "  Tweaks done: $ok of $n applied" -ForegroundColor Cyan

        # ---- Disk Cleanup after tweaks ----
        $curS = $global:UIStrings
        $doneWord  = if ($curS -and $curS.ContainsKey("TweaksDone"))     { $curS["TweaksDone"] }    else { "Done! Applied" }
        $ofWord    = if ($curS -and $curS.ContainsKey("TweaksOf"))       { $curS["TweaksOf"] }      else { "of" }
        $cleanWord = if ($curS -and $curS.ContainsKey("TweaksDiskClean")){ $curS["TweaksDiskClean"]}else { "tweaks. Running disk cleanup..." }
        $cleanMsg  = if ($curS -and $curS.ContainsKey("DiskCleanMsg"))   { $curS["DiskCleanMsg"] }  else { "Running disk cleanup in the background..." }
        $cleanDone = if ($curS -and $curS.ContainsKey("DiskCleanDone"))  { $curS["DiskCleanDone"] } else { "Disk cleanup finished." }

        & $script:setStatus "$doneWord $ok $ofWord $n $cleanWord" "#00CC6A"
        Write-Host "  [Disk Cleanup] Registering cleanmgr profile and launching..." -ForegroundColor DarkGray
        Write-WTLog "Post-tweak disk cleanup starting"

        # Pre-configure sageset:64 silently so /sagerun:64 runs without UI dialogs
        try {
            $sagePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
            $cleanTargets = @(
                "Active Setup Temp Folders","Downloaded Program Files","Internet Cache Files",
                "Memory Dump Files","Old ChkDsk Files","Previous Installations",
                "Recycle Bin","Setup Log Files","System error memory dump files",
                "System error minidump files","Temporary Files","Temporary Setup Files",
                "Thumbnail Cache","Update Cleanup","Windows Error Reporting Files","Windows Upgrade Log Files"
            )
            foreach ($t2 in $cleanTargets) {
                $keyPath = Join-Path $sagePath $t2
                if (Test-Path $keyPath) {
                    Set-ItemProperty $keyPath -Name "StateFlags0064" -Value 2 -Type DWord -EA SilentlyContinue
                }
            }
            # Launch cleanmgr /sagerun:64 as a background job so the UI stays responsive
            Start-Job -ScriptBlock {
                Start-Process "cleanmgr.exe" -ArgumentList "/sagerun:64" -Wait -WindowStyle Hidden
            } | Out-Null
            & $script:setStatus $cleanMsg "#0067C0"
            Write-WTLog "Disk cleanup launched (sagerun:64)"

            # Store in script scope so the timer tick can reliably access them
            $script:diskFinalMsg = "$doneWord $ok $ofWord $n tweaks. $cleanDone"

            # Poll the job in the background and update status when done
            $script:diskPollTimer = New-Object System.Windows.Threading.DispatcherTimer
            $script:diskPollTimer.Interval = [TimeSpan]::FromSeconds(3)
            $script:diskPollTimer.Add_Tick({
                $job = Get-Job | Where-Object { $_.State -eq "Completed" -and $_.Command -like "*cleanmgr*" }
                if ($job) {
                    $job | Remove-Job -Force -EA SilentlyContinue
                    $script:diskPollTimer.Stop()
                    & $script:setStatus $script:diskFinalMsg "#107C10"
                    Write-WTLog "Disk cleanup completed"
                }
            })
            $script:diskPollTimer.Start()
        } catch {
            Write-WTLog "Disk cleanup error: $_" "ERROR"
            & $script:setStatus "$doneWord $ok $ofWord $n tweaks. Reboot may be needed." "#00CC6A"
        }
    })

    # ================================================================
    #  BUILD SERVICES TAB
    # ================================================================
    $script:SvcCBs = @{}

    foreach ($svc in $global:ServicesList) {
        $svcCard = New-Object Windows.Controls.Border
        $svcCard.Background      = script:Brush $script:T.CardBG
        $svcCard.CornerRadius    = New-Object Windows.CornerRadius(8)
        $svcCard.BorderBrush     = script:Brush $script:T.CardBorder
        $svcCard.BorderThickness = New-Object Windows.Thickness(1)
        $svcCard.Padding         = New-Object Windows.Thickness(14,11,14,11)
        $svcCard.Margin          = New-Object Windows.Thickness(0,0,0,5)

        $sg = New-Object Windows.Controls.Grid
        $sc1 = New-Object Windows.Controls.ColumnDefinition; $sc1.Width = [Windows.GridLength]::Auto
        $sc2 = New-Object Windows.Controls.ColumnDefinition
        $sc3 = New-Object Windows.Controls.ColumnDefinition; $sc3.Width = [Windows.GridLength]::Auto
        $sg.ColumnDefinitions.Add($sc1); $sg.ColumnDefinitions.Add($sc2); $sg.ColumnDefinitions.Add($sc3)

        $scb = New-Object Windows.Controls.CheckBox
        $scb.VerticalAlignment = "Center"; $scb.Tag = $svc.Name
        [Windows.Controls.Grid]::SetColumn($scb, 0); $sg.Children.Add($scb) | Out-Null

        $sInfoSp = New-Object Windows.Controls.StackPanel; $sInfoSp.Margin = New-Object Windows.Thickness(12,0,12,0)
        $sNm = New-Object Windows.Controls.TextBlock; $sNm.Text = $svc.DisplayName; $sNm.FontSize = 13
        $sNm.FontWeight = [Windows.FontWeights]::SemiBold; $sNm.Foreground = script:Brush $script:T.Text1
        $sDs = New-Object Windows.Controls.TextBlock; $sDs.Text = $svc.Description; $sDs.FontSize = 11
        $sDs.Foreground = script:Brush $script:T.Text3
        $sDs.Margin = New-Object Windows.Thickness(0,3,0,0)
        $sNm2 = New-Object Windows.Controls.TextBlock; $sNm2.Text = $svc.Name; $sNm2.FontSize = 10
        $sNm2.Foreground = script:Brush $script:T.Text4
        $sInfoSp.Children.Add($sNm) | Out-Null; $sInfoSp.Children.Add($sDs) | Out-Null; $sInfoSp.Children.Add($sNm2) | Out-Null
        [Windows.Controls.Grid]::SetColumn($sInfoSp, 1); $sg.Children.Add($sInfoSp) | Out-Null

        $svcObj = Get-Service $svc.Name -ErrorAction SilentlyContinue
        $startType = if ($svcObj) { $svcObj.StartType } else { "Unknown" }
        $statusText = $startType; $statusColor = switch ($startType.ToString()) {
            "Automatic" { "#FC3E3E" }; "Manual" { "#FFB900" }; "Disabled" { "#27AE60" }
            default     { "#555555" }
        }
        $sBd = New-Object Windows.Controls.Border
        $sRgb = [Windows.Media.ColorConverter]::ConvertFromString($statusColor)
        $sBd.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(20,$sRgb.R,$sRgb.G,$sRgb.B))
        $sBd.BorderBrush  = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(60,$sRgb.R,$sRgb.G,$sRgb.B))
        $sBd.BorderThickness = New-Object Windows.Thickness(1); $sBd.CornerRadius = New-Object Windows.CornerRadius(4)
        $sBd.Padding = New-Object Windows.Thickness(8,3,8,3); $sBd.VerticalAlignment = "Center"
        $sTb = New-Object Windows.Controls.TextBlock; $sTb.Text = $statusText; $sTb.FontSize = 10; $sTb.FontWeight = [Windows.FontWeights]::SemiBold
        $sTb.Foreground = New-Object Windows.Media.SolidColorBrush($sRgb); $sBd.Child = $sTb
        [Windows.Controls.Grid]::SetColumn($sBd, 2); $sg.Children.Add($sBd) | Out-Null

        $svcCard.Child = $sg
        $ctrl["ServicePanel"].Children.Add($svcCard) | Out-Null
        $script:SvcCBs[$svc.Name] = $scb
    }

    $svcAction = {
        param([string]$action)
        $selected = $script:SvcCBs.GetEnumerator() | Where-Object { $_.Value.IsChecked }
        foreach ($kv in $selected) {
            $svcName = $kv.Key
            try {
                switch ($action) {
                    "Disable" { Stop-Service $svcName -Force -EA SilentlyContinue; Set-Service $svcName -StartupType Disabled -EA Stop }
                    "Manual"  { Set-Service $svcName -StartupType Manual -EA Stop }
                    "Enable"  { Set-Service $svcName -StartupType Automatic -EA Stop; Start-Service $svcName -EA SilentlyContinue }
                }
                Write-Host "  [${action}] $svcName" -ForegroundColor DarkGray
                Write-WTLog "Service ${action}: $svcName"
            } catch {
                Write-Host "  [FAIL] $svcName - $_" -ForegroundColor Red
                Write-WTLog "Service ${action} failed: $svcName - $_" "ERROR"
            }
        }
        & $script:setStatus "Service changes applied." "#00CC6A"
    }

    $ctrl["BtnSvcDisable"].Add_Click({ & $svcAction "Disable" })
    $ctrl["BtnSvcManual"].Add_Click({  & $svcAction "Manual"  })
    $ctrl["BtnSvcEnable"].Add_Click({  & $svcAction "Enable"  })

    # ================================================================
    #  REPAIR TAB - async SFC/DISM with live output
    # ================================================================
    $script:appendRepair = {
        param([string]$text)
        $ctrl["RepairOutput"].AppendText($text + "`n")
        $ctrl["RepairOutput"].ScrollToEnd()
        Write-Host "  $text" -ForegroundColor DarkGray
    }

    $ctrl["BtnSFC"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        $ctrl["RepairSpinner"].Visibility = "Visible"
        & $script:appendRepair "Running SFC /scannow ..."
        & $script:appendRepair "(This may take 5-15 minutes. GUI remains responsive.)"
        & $script:appendRepair ""
        $win.Dispatcher.Invoke([action]{}, "Render")

        $job = Start-Job -ScriptBlock { sfc /scannow 2>&1 | ForEach-Object { $_ } }
        $processed = ""
        while ($job.State -eq "Running") {
            Start-Sleep -Milliseconds 400
            $partial = Receive-Job $job -Keep 2>$null | Where-Object { $_ -and $_ -ne $processed }
            foreach ($line in $partial) {
                if ($line.Trim()) {
                    $ctrl["RepairOutput"].Dispatcher.Invoke([action]{
                        $ctrl["RepairOutput"].AppendText($line + "`n")
                        $ctrl["RepairOutput"].ScrollToEnd()
                    })
                }
            }
            $win.Dispatcher.Invoke([action]{}, "Background")
        }
        $final = Receive-Job $job | Out-String
        Remove-Job $job -Force

        $ctrl["RepairOutput"].Dispatcher.Invoke([action]{
            & $script:appendRepair ""
            & $script:appendRepair "SFC complete."
            & $script:appendRepair "Running DISM RestoreHealth ..."
        })

        $job2 = Start-Job -ScriptBlock { DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | ForEach-Object { $_ } }
        while ($job2.State -eq "Running") {
            Start-Sleep -Milliseconds 400
            $partial = Receive-Job $job2 -Keep 2>$null
            foreach ($line in $partial) {
                if ($line.Trim()) {
                    $ctrl["RepairOutput"].Dispatcher.Invoke([action]{
                        $ctrl["RepairOutput"].AppendText($line + "`n")
                        $ctrl["RepairOutput"].ScrollToEnd()
                    })
                }
            }
            $win.Dispatcher.Invoke([action]{}, "Background")
        }
        Remove-Job $job2 -Force
        $ctrl["RepairSpinner"].Visibility = "Collapsed"
        & $script:appendRepair ""
        & $script:appendRepair "SFC + DISM complete."
        Write-WTLog "SFC+DISM complete"
    })

    $ctrl["BtnClearTemp"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $script:appendRepair "Clearing temp files..."
        $result = Clear-TempFiles
        & $script:appendRepair $result
        & $script:setStatus $result "#00CC6A"
    })

    $ctrl["BtnFlushDNS"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $script:appendRepair "Flushing DNS cache..."
        $result = Invoke-FlushDNS
        & $script:appendRepair $result
        & $script:setStatus "DNS flushed." "#00CC6A"
    })

    $ctrl["BtnWsReset"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $script:appendRepair "Resetting Windows Store..."
        wsreset.exe 2>&1 | Out-Null
        & $script:appendRepair "Windows Store reset complete."
        & $script:setStatus "Windows Store reset." "#00CC6A"
    })

    $ctrl["BtnRestorePoint"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $script:appendRepair "Creating restore point..."
        $result = New-RestorePoint -Label "WinToolerV1 Manual"
        & $script:appendRepair $result
        & $script:setStatus $result "#00CC6A"
    })

    $ctrl["BtnNetReset"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $script:appendRepair "Resetting network stack..."
        $result = Reset-NetworkStack
        & $script:appendRepair $result
        & $script:setStatus "Network reset done. Reboot required." "#FFB900"
    })

    # ================================================================
    #  WINDOWS UPDATES TAB  (winget-native, no PSWindowsUpdate required)
    # ================================================================
    $script:appendUpdateLog = { param([string]$msg)
        $ctrl["UpdateOutput"].AppendText("$msg`n")
        $ctrl["UpdateOutput"].ScrollToEnd()
    }

    $ctrl["BtnRunUpdates"].Add_Click({
        if (-not $global:WingetPath) {
            & $script:appendUpdateLog "winget not found. Cannot check for updates."
            return
        }
        $ctrl["UpdateOutput"].Text = ""
        & $script:appendUpdateLog "Scanning for pending Windows updates via winget..."
        & $script:appendUpdateLog ""
        $win.Dispatcher.Invoke([action]{}, "Render")

        try {
            # winget upgrade lists pending updates without installing them
            $raw = & $global:WingetPath upgrade --disable-interactivity 2>&1
            $inTable = $false
            $found   = [System.Collections.Generic.List[string]]::new()
            foreach ($line in $raw) {
                if ($line -match 'Name\s+Id\s+Version\s+Available') { $inTable = $true; continue }
                if (-not $inTable) { continue }
                if ($line -match '^[-\s]+$' -or $line -notmatch '\S') { continue }
                $parts = $line -split '\s{2,}'
                if ($parts.Count -ge 2) { $found.Add($line.Trim()) }
            }

            if ($found.Count -eq 0) {
                & $script:appendUpdateLog "No app updates found via winget."
            } else {
                & $script:appendUpdateLog "Found $($found.Count) pending update(s):"
                foreach ($l in $found) { & $script:appendUpdateLog "  $l" }
                & $script:appendUpdateLog ""
            }

            # Trigger Windows Update service scan via UsoClient (no reboot forced)
            & $script:appendUpdateLog "Triggering Windows Update scan (UsoClient ScanInstallWait)..."
            $win.Dispatcher.Invoke([action]{}, "Render")
            $proc = Start-Process -FilePath "UsoClient.exe" -ArgumentList "ScanInstallWait" `
                        -NoNewWindow -PassThru -ErrorAction SilentlyContinue
            if ($proc) {
                $proc.WaitForExit(30000) | Out-Null
                & $script:appendUpdateLog "Windows Update scan complete."
            } else {
                # Fallback for older Windows builds
                Start-Process -FilePath "wuauclt.exe" -ArgumentList "/detectnow /updatenow" `
                    -NoNewWindow -ErrorAction SilentlyContinue
                & $script:appendUpdateLog "Windows Update triggered (wuauclt /detectnow)."
            }
            & $script:appendUpdateLog ""
            & $script:appendUpdateLog "Tip: Open Settings > Windows Update to see pending OS updates."
            Write-WTLog "Windows Update scan triggered via UsoClient"
        } catch {
            & $script:appendUpdateLog "Error: $_"
            Write-WTLog "Windows Update error: $_" "ERROR"
        }
    })

    $ctrl["BtnPauseUpdates"].Add_Click({
        try {
            $date = (Get-Date).AddDays(7).ToString("yyyy-MM-ddTHH:mm:ssZ")
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
                -Name "PauseUpdatesStartTime" -Value (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ') -Type String -Force -EA Stop
            Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
                -Name "PauseUpdatesExpiryTime" -Value $date -Type String -Force -EA Stop
            $ctrl["UpdateOutput"].AppendText("Updates paused for 7 days.`n")
            Write-WTLog "Updates paused 7 days"
        } catch {
            $ctrl["UpdateOutput"].AppendText("Could not pause updates: $_`n")
        }
    })

    $ctrl["BtnResumeUpdates"].Add_Click({
        try {
            Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
                -Name "PauseUpdatesExpiryTime" -ErrorAction SilentlyContinue
            $ctrl["UpdateOutput"].AppendText("Updates resumed.`n")
            Write-WTLog "Updates resumed"
        } catch {
            $ctrl["UpdateOutput"].AppendText("Error: $_`n")
        }
    })


    # ================================================================
    #  SHOW WINDOW
    # ================================================================
    & $script:setStatus "Ready - $($global:AppCatalog.Count) apps | $($global:TweaksCatalog.Count) tweaks | $($global:ServicesList.Count) services"
    $win.ShowDialog() | Out-Null
}


# ================================================================
#  STARTUP SELECTION SCREEN  (Language only - light mode always)
# ================================================================
function Show-StartupScreen {
    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase

    $result = @{ Language = "EN"; Theme = "Light" }

    [xml]$XAML = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="WinToolerV1"
    Width="460"
    WindowStartupLocation="CenterScreen"
    Background="#D8EAF5"
    ResizeMode="NoResize"
    SizeToContent="Height"
    FontFamily="Segoe UI Variable Text, Segoe UI, Sans-Serif">

  <Window.Resources>
    <Style x:Key="SelBtn" TargetType="Button">
      <Setter Property="Background"      Value="#FFFFFF"/>
      <Setter Property="Foreground"      Value="#444444"/>
      <Setter Property="BorderBrush"     Value="#CCCCCC"/>
      <Setter Property="BorderThickness" Value="2"/>
      <Setter Property="Cursor"          Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd"
                    Background="{TemplateBinding Background}"
                    BorderBrush="{TemplateBinding BorderBrush}"
                    BorderThickness="{TemplateBinding BorderThickness}"
                    CornerRadius="12" Padding="0">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="BorderBrush" Value="#0067C0"/>
                <Setter TargetName="bd" Property="Background"  Value="#EEF5FF"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>

    <Style x:Key="PrimaryBtn" TargetType="Button">
      <Setter Property="Background"      Value="#0067C0"/>
      <Setter Property="Foreground"      Value="White"/>
      <Setter Property="FontWeight"      Value="SemiBold"/>
      <Setter Property="FontSize"        Value="14"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Cursor"          Value="Hand"/>
      <Setter Property="Padding"         Value="32,12"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}"
                    CornerRadius="10" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#0078D4"/>
              </Trigger>
              <Trigger Property="IsPressed" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#005AA8"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
  </Window.Resources>

  <Grid Margin="32,28,32,28">
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="24"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="16"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="28"/>
      <RowDefinition Height="Auto"/>
    </Grid.RowDefinitions>

    <!-- Logo + Title -->
    <StackPanel Grid.Row="0" HorizontalAlignment="Center">
      <Border Width="64" Height="64" CornerRadius="16" Background="Transparent"
              HorizontalAlignment="Center" Margin="0,0,0,14">
        <Image x:Name="StartupIcon" Width="64" Height="64"
               RenderOptions.BitmapScalingMode="HighQuality"
               Stretch="UniformToFill"/>
      </Border>
      <TextBlock Text="WinToolerV1" FontSize="26" FontWeight="Bold"
                 Foreground="#1A1A1A" HorizontalAlignment="Center"/>
      <TextBlock Text="v0.6.1 BETA  by ErickP (Eperez98)" FontSize="12"
                 Foreground="#999999" HorizontalAlignment="Center" Margin="0,4,0,0"/>
    </StackPanel>

    <!-- Language label -->
    <TextBlock Grid.Row="2" Text="Select Language / Seleccionar Idioma"
               FontSize="11" FontWeight="SemiBold" Foreground="#777777"
               HorizontalAlignment="Center"/>

    <!-- Language buttons -->
    <Grid Grid.Row="4">
      <Grid.ColumnDefinitions>
        <ColumnDefinition Width="*"/>
        <ColumnDefinition Width="16"/>
        <ColumnDefinition Width="*"/>
      </Grid.ColumnDefinitions>

      <Button x:Name="BtnEN" Grid.Column="0" Style="{StaticResource SelBtn}" Height="86">
        <StackPanel>
          <TextBlock Text="EN" FontSize="28" FontWeight="Black"
                     Foreground="#1A1A1A" HorizontalAlignment="Center"/>
          <TextBlock Text="English" FontSize="13" FontWeight="SemiBold"
                     Foreground="#444444" HorizontalAlignment="Center" Margin="0,4,0,0"/>
          <TextBlock Text="United States" FontSize="10"
                     Foreground="#999999" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>
      </Button>

      <Button x:Name="BtnES" Grid.Column="2" Style="{StaticResource SelBtn}" Height="86">
        <StackPanel>
          <TextBlock Text="ES" FontSize="28" FontWeight="Black"
                     Foreground="#1A1A1A" HorizontalAlignment="Center"/>
          <TextBlock Text="Espanol" FontSize="13" FontWeight="SemiBold"
                     Foreground="#444444" HorizontalAlignment="Center" Margin="0,4,0,0"/>
          <TextBlock Text="Espana / Latinoamerica" FontSize="10"
                     Foreground="#999999" HorizontalAlignment="Center" Margin="0,2,0,0"/>
        </StackPanel>
      </Button>
    </Grid>

    <!-- Launch button -->
    <Button Grid.Row="6" x:Name="BtnLaunch"
            Style="{StaticResource PrimaryBtn}"
            Content="Launch WinToolerV1"
            HorizontalAlignment="Center"/>
  </Grid>
</Window>
'@

    $reader  = New-Object System.Xml.XmlNodeReader($XAML)
    $sWin    = [Windows.Markup.XamlReader]::Load($reader)

    # Load icon into startup screen — use $global:Root set by WinToolerV1.ps1
    try {
        $iconBase = if ($global:Root) { $global:Root } else { $PSScriptRoot }
        $iconPath = Join-Path $iconBase "WinToolerV1_icon.png"
        if (Test-Path $iconPath) {
            $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
            $bmp.BeginInit()
            $bmp.UriSource       = New-Object System.Uri((Resolve-Path $iconPath).Path, [System.UriKind]::Absolute)
            $bmp.DecodePixelWidth = 64
            $bmp.CacheOption      = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bmp.EndInit()
            $bmp.Freeze()
            $startupImg = $sWin.FindName("StartupIcon")
            if ($startupImg) { $startupImg.Source = $bmp }
            $sWin.Icon = $bmp
        }
    } catch {}

    $btnEN = $sWin.FindName("BtnEN")
    $btnES = $sWin.FindName("BtnES")

    $accentBrush = New-Object Windows.Media.SolidColorBrush([Windows.Media.ColorConverter]::ConvertFromString("#0067C0"))
    $dimBrush    = New-Object Windows.Media.SolidColorBrush([Windows.Media.ColorConverter]::ConvertFromString("#CCCCCC"))

    $setLangHL = {
        param([string]$lang)
        $btnEN.BorderBrush  = if ($lang -eq "EN") { $accentBrush } else { $dimBrush }
        $btnES.BorderBrush  = if ($lang -eq "ES") { $accentBrush } else { $dimBrush }
        $result["Language"] = $lang
    }

    & $setLangHL "EN"

    $btnEN.Add_Click({ & $setLangHL "EN" })
    $btnES.Add_Click({ & $setLangHL "ES" })

    $launchBtn = $sWin.FindName("BtnLaunch")
    $launchBtn.Add_Click({ $sWin.DialogResult = $true; $sWin.Close() })

    $sWin.ShowDialog() | Out-Null
    return $result
}
