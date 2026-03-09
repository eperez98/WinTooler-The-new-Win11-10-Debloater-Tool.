# scripts/gui.ps1
# WinToolerV1 GUI - Full WPF interface
# Features: Dark/Light mode, macOS-style icons, Tweak templates,
#           App Updates tab, Uninstall tab, Async SFC/DISM

function Start-WinToolerGUI {

    Add-Type -AssemblyName PresentationFramework
    Add-Type -AssemblyName PresentationCore
    Add-Type -AssemblyName WindowsBase
    Add-Type -AssemblyName System.Windows.Forms

    $script:IsDark = $false

    # ----------------------------------------------------------------
    #  THEME HELPERS - called at build time and on toggle
    # ----------------------------------------------------------------
    $script:T = @{}  # theme palette - rebuilt by Set-Theme

    function script:Set-Theme {
        param([bool]$dark)
        # Light mode only - dark param ignored
        $script:T = @{
            WinBG       = "#F0F2F5"; SidebarBG = "#FFFFFF"; SidebarBorder = "#E5E5E5"
            Surface1    = "#FFFFFF"; Surface2  = "#F8F9FA"; Surface3      = "#F0F2F5"
            Border1     = "#E5E5E5"; Border2   = "#D1D1D1"
            Text1       = "#1A1A1A"; Text2     = "#323130"; Text3        = "#757575"; Text4 = "#999999"
            Accent      = "#0067C0"; AccentH   = "#0078D4"; AccentP      = "#005AA8"
            NavBtnFG    = "#5A5A5A"; NavActBG  = "#EEF3FC"; NavActFG     = "#0067C0"
            CardBG      = "#FFFFFF"; CardBorder = "#E5E5E5"
            InputBG     = "#FFFFFF"; StatusBG  = "#F8F9FA"; StatusBorder = "#E5E5E5"
            Green       = "#107C10"; Red       = "#C42B1C"; Yellow       = "#B06B00"; Orange = "#D83B01"
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
    $lang = if ($global:UILanguage -eq "ES") { "ES" } else { "EN" }
    $S = @{}   # UI strings - keyed by control/label name

    if ($lang -eq "ES") {
        $S = @{
            # Nav labels
            NavInstall    = "Instalar Apps";    NavUninstall   = "Desinstalar"
            NavAppUpdates = "Act. de Apps";     NavTweaks      = "Ajustes"
            NavServices   = "Servicios";        NavRepair      = "Reparar"
            NavUpdates    = "Windows Update";   NavDNS         = "DNS Changer"; NavAbout = "Acerca de"
            # Page titles
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
            # Buttons
            BtnSelectAll     = "Selec. Todo";   BtnDeselectAll  = "Ninguno"
            BtnInstall       = "Instalar Seleccionados"
            BtnInstallCancel = "Cancelar"
            BtnRefreshUn     = "Actualizar Lista"
            BtnUninstall     = "Desinstalar Seleccionados"
            BtnUpdateAll     = "Actualizar Todo"
            BtnUpdateSel     = "Actualizar Selec."
            BtnReCheck       = "Re-Escanear"
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
            SearchPlaceholder = "Buscar...";     Ready = "Listo"
            StatusReady      = "Listo"
            AboutVersion     = "Version";        AboutLicense = "Licencia"
            AboutInspired    = "Inspirado en"
            AboutLog         = "Archivo de log"
        }
    } else {
        $S = @{
            NavInstall    = "Install Apps";     NavUninstall   = "Uninstall"
            NavAppUpdates = "App Updates";      NavTweaks      = "Tweaks"
            NavServices   = "Services";         NavRepair      = "Repair"
            NavUpdates    = "Windows Update";   NavAbout       = "About"
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
            BtnUpdateAll     = "Update All"
            BtnUpdateSel     = "Update Selected"
            BtnReCheck       = "Re-Check"
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
    Title="WinToolerV1 v0.6 BETA Build 4.034"
    Width="1180" Height="780"
    MinWidth="980" MinHeight="640"
    WindowStartupLocation="CenterScreen"
    Background="#F0F2F5"
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
              <!-- macOS-style app icon -->
              <Border Grid.Column="0" Width="44" Height="44" CornerRadius="12"
                      Background="#0078D4">
                <Grid>
                  <Ellipse Width="20" Height="20" Fill="#FFFFFF" Opacity="0.15"
                           HorizontalAlignment="Left" VerticalAlignment="Top"
                           Margin="6,5,0,0"/>
                  <TextBlock Text="W" FontSize="22" FontWeight="Black"
                             Foreground="#1A1A1A"
                             HorizontalAlignment="Center" VerticalAlignment="Center"/>
                </Grid>
              </Border>
            </Grid>
            <TextBlock x:Name="SidebarTitle" Text="WinTooler" FontSize="16" FontWeight="Bold" Foreground="#1A1A1A"/>
            <TextBlock x:Name="SidebarSub" Text="V1  by Eperez98" FontSize="11" Foreground="#777777" Margin="0,2,0,0"/>
          </StackPanel>

          <!-- Nav items -->
          <StackPanel Grid.Row="1" Margin="0,0,0,0">

            <TextBlock Text="APPS" FontSize="10" FontWeight="SemiBold"
                       Foreground="#999999" Margin="20,12,0,5"/>

            <Button x:Name="NavInstall" Style="{StaticResource NavBtnActive}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#E3F0FF" Margin="0,0,8,0">
                  <TextBlock Text="&#x2B07;" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#4FC3F7"/>
                </Border>
                <TextBlock Text="Install Apps"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavUninstall" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#FFE8E8" Margin="0,0,8,0">
                  <TextBlock Text="&#x2715;" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#FF6B6B"/>
                </Border>
                <TextBlock Text="Uninstall"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavAppUpdates" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#E8F5E9" Margin="0,0,8,0">
                  <TextBlock Text="&#x2B06;" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#4CAF50"/>
                </Border>
                <TextBlock Text="App Updates"/>
                <Border x:Name="UpdateBadge" Background="#FC3E3E" CornerRadius="10"
                        Padding="5,1" Margin="6,0,0,0" Visibility="Collapsed">
                  <TextBlock x:Name="UpdateBadgeTxt" Text="0" FontSize="10"
                             FontWeight="Bold" Foreground="#1A1A1A"/>
                </Border>
              </StackPanel>
            </Button>

            <TextBlock Text="SYSTEM" FontSize="10" FontWeight="SemiBold"
                       Foreground="#999999" Margin="20,10,0,5"/>

            <Button x:Name="NavTweaks" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#EDEDFF" Margin="0,0,8,0">
                  <TextBlock Text="&#x2699;" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#9C9CFF"/>
                </Border>
                <TextBlock Text="Tweaks"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavServices" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#E3EFF8" Margin="0,0,8,0">
                  <TextBlock Text="&#x25B6;" FontSize="10" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#64B5F6"/>
                </Border>
                <TextBlock Text="Services"/>
              </StackPanel>
            </Button>

            <TextBlock Text="TOOLS" FontSize="10" FontWeight="SemiBold"
                       Foreground="#999999" Margin="20,10,0,5"/>

            <Button x:Name="NavRepair" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#FFF3E0" Margin="0,0,8,0">
                  <TextBlock Text="&#x1F527;" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#FFB74D"/>
                </Border>
                <TextBlock Text="Repair"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavUpdates" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#E8F5E9" Margin="0,0,8,0">
                  <TextBlock Text="&#x21BA;" FontSize="13" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#81C784"/>
                </Border>
                <TextBlock Text="Windows Update"/>
              </StackPanel>
            </Button>


            <Button x:Name="NavDNS" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#E8F8FF" Margin="0,0,8,0">
                  <TextBlock Text="&#x1F310;" FontSize="11" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#0099CC"/>
                </Border>
                <TextBlock Text="DNS Changer"/>
              </StackPanel>
            </Button>

            <Button x:Name="NavAbout" Style="{StaticResource NavBtn}">
              <StackPanel Orientation="Horizontal">
                <Border Width="22" Height="22" CornerRadius="6" Background="#F3EDFF" Margin="0,0,8,0">
                  <TextBlock Text="&#x2139;" FontSize="12" HorizontalAlignment="Center" VerticalAlignment="Center" Foreground="#CE93D8"/>
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

          <!-- PAGE: INSTALL -->
          <Grid x:Name="PageInstall" Visibility="Visible">
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="190"/>
              <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Category sidebar -->
            <Border x:Name="CatSidebar" Grid.Column="0" Background="#F7F7F7"
                    BorderBrush="#E0E0E0" BorderThickness="0,0,1,0">
              <ScrollViewer VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="CatPanel" Margin="8,12"/>
              </ScrollViewer>
            </Border>

            <!-- App list -->
            <Grid Grid.Column="1">
              <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
              </Grid.RowDefinitions>

              <!-- Toolbar -->
              <Border x:Name="InstallToolbar" Grid.Row="0" Padding="16,12" Background="#FFFFFF"
                      BorderBrush="#E8E8E8" BorderThickness="0,0,0,1">
                <Grid>
                  <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                  </Grid.ColumnDefinitions>
                  <TextBox x:Name="InstallSearch" Grid.Column="0"
                           Style="{StaticResource SearchBox}"
                           Text="" Margin="0,0,10,0"/>
                  <Button x:Name="BtnSelectAll"   Grid.Column="1" Content="Select All"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0"/>
                  <Button x:Name="BtnDeselectAll" Grid.Column="2" Content="None"
                          Style="{StaticResource BtnGhost}" Margin="0,0,6,0"/>
                  <Border x:Name="SelCountBadge" Grid.Column="3" Background="#F0F0F0" CornerRadius="8"
                          Padding="10,0" VerticalAlignment="Stretch">
                    <TextBlock x:Name="SelCountTxt" Text="0 selected"
                               FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
                  </Border>
                </Grid>
              </Border>

              <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto"
                            HorizontalScrollBarVisibility="Disabled">
                <StackPanel x:Name="AppPanel" Margin="16,12,12,12"/>
              </ScrollViewer>

              <!-- Bottom install bar -->
              <Border x:Name="InstallBottomBar" Grid.Row="2" Background="#F5F5F5"
                      BorderBrush="#E0E0E0" BorderThickness="0,1,0,0"
                      Padding="16,12">
                <Grid>
                  <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                  </Grid.RowDefinitions>
                  <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="0,0,0,8">
                    <Button x:Name="BtnInstall" Content="Install Selected"
                            Style="{StaticResource BtnAccent}"
                            IsEnabled="False" Margin="0,0,8,0"/>
                    <Button x:Name="BtnInstallCancel" Content="Cancel"
                            Style="{StaticResource BtnGhost}"
                            Visibility="Collapsed" Margin="0,0,8,0"/>
                    <TextBlock x:Name="InstallProgCount" Text=""
                               FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
                  </StackPanel>
                  <StackPanel x:Name="InstallProgressPanel" Grid.Row="1"
                              Visibility="Collapsed">
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

          <!-- PAGE: UNINSTALL -->
          <Grid x:Name="PageUninstall" Visibility="Collapsed">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Border x:Name="UninstallToolbar" Grid.Row="0" Padding="16,12" Background="#FFFFFF"
                    BorderBrush="#E8E8E8" BorderThickness="0,0,0,1">
              <Grid>
                <Grid.ColumnDefinitions>
                  <ColumnDefinition Width="*"/>
                  <ColumnDefinition Width="Auto"/>
                  <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBox x:Name="UninstallSearch" Grid.Column="0"
                         Style="{StaticResource SearchBox}"
                         Text="" Margin="0,0,10,0"/>
                <Button x:Name="BtnRefreshUninstall" Grid.Column="1"
                        Content="Refresh List" Style="{StaticResource BtnGhost}"
                        Margin="0,0,6,0"/>
                <TextBlock x:Name="UninstallCount" Grid.Column="2"
                           FontSize="12" Foreground="#777777" VerticalAlignment="Center"
                           Margin="10,0,0,0"/>
              </Grid>
            </Border>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
              <StackPanel x:Name="UninstallPanel" Margin="16,12,12,12"/>
            </ScrollViewer>
            <Border Grid.Row="2" Background="#F5F5F5"
                    BorderBrush="#E0E0E0" BorderThickness="0,1,0,0" Padding="16,12">
              <StackPanel Orientation="Horizontal">
                <Button x:Name="BtnUninstall" Content="Uninstall Selected"
                        Style="{StaticResource BtnDanger}"
                        IsEnabled="False" Margin="0,0,10,0"/>
                <TextBlock x:Name="UninstallSelTxt" Text="0 selected"
                           FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
          </Grid>

          <!-- PAGE: APP UPDATES -->
          <Grid x:Name="PageAppUpdates" Visibility="Collapsed">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
              <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Border Grid.Row="0" Padding="16,12" Background="#FFFFFF"
                    BorderBrush="#E8E8E8" BorderThickness="0,0,0,1">
              <StackPanel Orientation="Horizontal">
                <TextBlock Text="Apps scanned at startup. Re-check with button below."
                           FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
            <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto">
              <StackPanel x:Name="AppUpdatePanel" Margin="16,12,12,12"/>
            </ScrollViewer>
            <Border Grid.Row="2" Background="#F5F5F5"
                    BorderBrush="#E0E0E0" BorderThickness="0,1,0,0" Padding="16,12">
              <StackPanel Orientation="Horizontal">
                <Button x:Name="BtnUpdateAll" Content="Update All"
                        Style="{StaticResource BtnAccent}"
                        IsEnabled="False" Margin="0,0,10,0"/>
                <Button x:Name="BtnUpdateSelected" Content="Update Selected"
                        Style="{StaticResource BtnGhost}"
                        IsEnabled="False" Margin="0,0,10,0"/>
                <Button x:Name="BtnReCheckUpdates" Content="Re-Check"
                        Style="{StaticResource BtnGhost}"
                        Margin="0,0,10,0"/>
                <TextBlock x:Name="UpdateStatusTxt" Text=""
                           FontSize="12" Foreground="#777777" VerticalAlignment="Center"/>
              </StackPanel>
            </Border>
          </Grid>

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

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#F8F8F8"
                      BorderBrush="#E0E0E0" BorderThickness="1" Width="200">
                <Button x:Name="BtnSFC" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#1A2A3A" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F6E1;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="SFC + DISM" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Full system file check" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#F8F8F8"
                      BorderBrush="#E0E0E0" BorderThickness="1" Width="200">
                <Button x:Name="BtnClearTemp" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#2A1A0A" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F5D1;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Clear Temp" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Remove junk files" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#F8F8F8"
                      BorderBrush="#E0E0E0" BorderThickness="1" Width="200">
                <Button x:Name="BtnFlushDNS" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#0A2A1A" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F310;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Flush DNS" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Clear DNS resolver cache" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#F8F8F8"
                      BorderBrush="#E0E0E0" BorderThickness="1" Width="200">
                <Button x:Name="BtnWsReset" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#2A0A2A" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F6D2;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Reset Store" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Fix Microsoft Store issues" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#F8F8F8"
                      BorderBrush="#E0E0E0" BorderThickness="1" Width="200">
                <Button x:Name="BtnRestorePoint" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#1A2A1A" Margin="0,0,0,10">
                      <TextBlock Text="&#x1F4BE;" FontSize="22"
                                 HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                    <TextBlock Text="Restore Point" FontSize="13" FontWeight="SemiBold" Foreground="#1A1A1A"/>
                    <TextBlock Text="Save system snapshot now" FontSize="10" Foreground="#777777" Margin="0,3,0,0" TextWrapping="Wrap"/>
                  </StackPanel>
                </Button>
              </Border>

              <Border Margin="0,0,12,12" CornerRadius="12" Background="#F8F8F8"
                      BorderBrush="#E0E0E0" BorderThickness="1" Width="200">
                <Button x:Name="BtnNetReset" Background="Transparent" BorderThickness="0"
                        Cursor="Hand" Padding="18,16">
                  <StackPanel>
                    <Border Width="44" Height="44" CornerRadius="12" Background="#2A1A0A" Margin="0,0,0,10">
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


          <!-- PAGE: DNS CHANGER -->
          <Grid x:Name="PageDNS" Visibility="Collapsed">
            <Grid.RowDefinitions>
              <RowDefinition Height="Auto"/>
              <RowDefinition Height="*"/>
            </Grid.RowDefinitions>

            <!-- DNS providers grid -->
            <ScrollViewer Grid.Row="0" VerticalScrollBarVisibility="Disabled">
              <WrapPanel x:Name="DNSCardPanel" Margin="20,16,20,0" Orientation="Horizontal"/>
            </ScrollViewer>

            <!-- Output log -->
            <Border Grid.Row="1" Margin="20,16,20,20" CornerRadius="10"
                    Background="#FFFFFF" BorderBrush="#E5E5E5" BorderThickness="1">
              <Grid>
                <Grid.RowDefinitions>
                  <RowDefinition Height="Auto"/>
                  <RowDefinition Height="*"/>
                </Grid.RowDefinitions>
                <Border Grid.Row="0" Background="#F8F9FA" CornerRadius="10,10,0,0"
                        BorderBrush="#E5E5E5" BorderThickness="0,0,0,1" Padding="14,9">
                  <StackPanel Orientation="Horizontal">
                    <TextBlock Text="DNS Output" FontSize="11" FontWeight="SemiBold" Foreground="#5A5A5A"/>
                    <TextBlock x:Name="DNSStatusTxt" FontSize="11" Foreground="#0067C0"
                               Margin="10,0,0,0" Visibility="Collapsed"/>
                  </StackPanel>
                </Border>
                <ScrollViewer Grid.Row="1" Height="160" VerticalScrollBarVisibility="Auto">
                  <TextBox x:Name="DNSOutput" Background="Transparent"
                           Foreground="#323130" FontFamily="Consolas, Courier New"
                           FontSize="11" IsReadOnly="True" BorderThickness="0"
                           TextWrapping="Wrap" Padding="14,10"/>
                </ScrollViewer>
              </Grid>
            </Border>
          </Grid>

          <!-- PAGE: ABOUT -->
          <Grid x:Name="PageAbout" Visibility="Collapsed">
            <ScrollViewer VerticalScrollBarVisibility="Auto">
              <StackPanel Margin="40,30" MaxWidth="500" HorizontalAlignment="Left">
                <Border Width="72" Height="72" CornerRadius="18" Background="#0078D4"
                        Margin="0,0,0,20" HorizontalAlignment="Left">
                  <Grid>
                    <Ellipse Width="28" Height="28" Fill="White" Opacity="0.1"
                             HorizontalAlignment="Left" VerticalAlignment="Top" Margin="10,8,0,0"/>
                    <TextBlock Text="W" FontSize="36" FontWeight="Black" Foreground="#1A1A1A"
                               HorizontalAlignment="Center" VerticalAlignment="Center"/>
                  </Grid>
                </Border>
                <TextBlock x:Name="AboutTitle" Text="WinToolerV1" FontSize="28" FontWeight="Bold" Foreground="#1A1A1A"/>
                <TextBlock x:Name="AboutSub" Text="by ErickP (Eperez98)" FontSize="13" Foreground="#0067C0" Margin="0,4,0,20"/>

                <!-- Version info card -->
                <Border x:Name="AboutInfoCard" Background="#FFFFFF" CornerRadius="10" Padding="20,16"
                        BorderBrush="#E0E0E0" BorderThickness="1">
                  <StackPanel>
                    <Grid Margin="0,0,0,10">
                      <TextBlock Text="Version"     Foreground="#777777"/>
                      <TextBlock x:Name="AboutVersion" Text="0.6 BETA Build 4.034" Foreground="#1A1A1A" HorizontalAlignment="Right"/>
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
                        <Run FontWeight="SemiBold">In-App Language Toggle</Run>
                        <Run Foreground="#666666"> - Switch EN / ES at any time without restarting</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#0067C0" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">Disk Cleaner</Run>
                        <Run Foreground="#666666"> - Deep scan for junk files, update caches and WinSxS backups</Run>
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
                    <StackPanel Orientation="Horizontal" Margin="0,0,0,7">
                      <TextBlock Text="&#x25CF;" Foreground="#C45000" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">More Languages</Run>
                        <Run Foreground="#666666"> - French, Portuguese, German and Italian UI translations</Run>
                      </TextBlock>
                    </StackPanel>
                    <StackPanel Orientation="Horizontal">
                      <TextBlock Text="&#x25CF;" Foreground="#C45000" FontSize="9" Margin="0,3,10,0"/>
                      <TextBlock TextWrapping="Wrap" MaxWidth="400" FontSize="12" Foreground="#333333">
                        <Run FontWeight="SemiBold">ISO Downloader</Run>
                        <Run Foreground="#666666"> - Re-implemented with a stable region-agnostic method</Run>
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
        "NavInstall","NavUninstall","NavAppUpdates","NavTweaks","NavServices","NavRepair","NavUpdates","NavDNS","NavAbout",
        "PageInstall","PageUninstall","PageAppUpdates","PageTweaks","PageServices","PageRepair","PageUpdates","PageDNS","PageAbout",
        "PageTitle","PageSubtitle","OsBadge","WingetDot","WingetStatus","AboutOS",
        
        "UpdateBadge","UpdateBadgeTxt",
        "InstallSearch","CatPanel","AppPanel","BtnSelectAll","BtnDeselectAll","SelCountTxt",
        "BtnInstall","BtnInstallCancel","InstallProgressPanel","InstallProgLabel","InstallProgCount","InstallProgBar",
        "UninstallSearch","UninstallPanel","UninstallCount","BtnRefreshUninstall","BtnUninstall","UninstallSelTxt",
        "AppUpdatePanel","BtnUpdateAll","BtnUpdateSelected","BtnReCheckUpdates","UpdateStatusTxt",
        "TweakSearch","TweakPanel","TweakCountLabel","BtnCheckAll","BtnUncheckAll","BtnApplyTweaks","BtnUndoTweaks",
        "TplNone","TplStandard","TplMinimal","TplHeavy",
        "ServicePanel","BtnSvcDisable","BtnSvcManual","BtnSvcEnable",
        "BtnSFC","BtnClearTemp","BtnFlushDNS","BtnWsReset","BtnRestorePoint","BtnNetReset",
        "RepairOutput","RepairSpinner",
        "BtnRunUpdates","BtnPauseUpdates","BtnResumeUpdates","UpdateOutput",
        "BtnOpenLog","LogPathTxt","StatusBar","ClockText",
        "CatSidebar","InstallToolbar","SelCountBadge","InstallBottomBar",
        "SidebarTitle","SidebarSub","SidebarFooter","WingetLabel",
        "UninstallToolbar","UninstallBottomBar",
        "AppUpdatesToolbar","AppUpdatesBottomBar",
        "TweaksToolbar","TweaksBottomBar","ServicesBottomBar",
        "RepairOutputBorder","RepairOutputHeader","WinUpdateOutputBorder",
        "AboutInfoCard","RoadmapV7Card","RoadmapV8Card",
        "AboutTitle","AboutSub","AboutVersion",
        "DNSCardPanel","DNSOutput","DNSStatusTxt"
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
            "NavInstall"="Install"; "NavUninstall"="Uninstall"; "NavAppUpdates"="AppUpdates"
            "NavTweaks"="Tweaks"; "NavServices"="Services"; "NavRepair"="Repair"
            "NavUpdates"="Updates"; "NavDNS"="DNS"; "NavAbout"="About"
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
        $pageNames = @("PageInstall","PageUninstall","PageAppUpdates","PageTweaks",
                       "PageServices","PageRepair","PageUpdates","PageDNS","PageAbout")
        foreach ($n in $pageNames) {
            if ($ctrl[$n]) { $ctrl[$n].Background = script:Brush $t.WinBG }
        }

        # -- Repaint all hardcoded-dark XAML surfaces -----------------------------
        # Toolbars and sidebars
        $surfaceNames = @(
            "CatSidebar","InstallToolbar","UninstallToolbar",
            "AppUpdatesToolbar","TweaksToolbar"
        )
        foreach ($n in $surfaceNames) {
            if ($ctrl[$n]) {
                $ctrl[$n].Background  = script:Brush $t.Surface1
                $ctrl[$n].BorderBrush = script:Brush $t.Border1
            }
        }
        # Bottom action bars
        $bottomNames = @(
            "InstallBottomBar","UninstallBottomBar","AppUpdatesBottomBar",
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
            "PageTitle","PageSubtitle","WingetStatus","OsBadge","UpdateBadgeTxt",
            "RepairSpinner",
            "StatusBar","ClockText","InstallProgLabel","InstallProgCount",
            "TweakCountLabel","UpdateStatusTxt","UninstallCount","UninstallSelTxt"
        )
        foreach ($n in $specText) {
            if ($ctrl[$n]) { $ctrl[$n].Foreground = script:Brush $t.Text2 }
        }
        # Titles stay bright
        if ($ctrl["PageTitle"])    { $ctrl["PageTitle"].Foreground    = script:Brush $t.Text1 }
        if ($ctrl["PageSubtitle"]) { $ctrl["PageSubtitle"].Foreground = script:Brush $t.Text3 }

        # Search boxes
        foreach ($n in @("InstallSearch","TweakSearch","UninstallSearch")) {
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

        if ($ctrl["AppUpdatePanel"] -and $ctrl["AppUpdatePanel"].Children.Count -gt 0) {
            foreach ($row in $ctrl["AppUpdatePanel"].Children) {
                if ($row.GetType().Name -eq "Border" -and $row.Child -and $row.Child.GetType().Name -eq "Grid") {
                    $row.Background  = script:Brush $t.CardBG
                    $row.BorderBrush = script:Brush $t.CardBorder
                    $grid = $row.Child
                    foreach ($col in $grid.Children) {
                        if ($col.GetType().Name -eq "StackPanel") {
                            $kids = @($col.Children)
                            if ($kids.Count -ge 1) { $kids[0].Foreground = script:Brush $t.Text1 }
                        }
                    }
                } elseif ($row.GetType().Name -eq "TextBlock") {
                    $row.Foreground = script:Brush $t.Text3
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
    $pages   = @("Install","Uninstall","AppUpdates","Tweaks","Services","Repair","Updates","DNS","About")
    $navBtns = @{
        "Install"    = $ctrl["NavInstall"]
        "Uninstall"  = $ctrl["NavUninstall"]
        "AppUpdates" = $ctrl["NavAppUpdates"]
        "Tweaks"     = $ctrl["NavTweaks"]
        "Services"   = $ctrl["NavServices"]
        "Repair"     = $ctrl["NavRepair"]
        "Updates"    = $ctrl["NavUpdates"]
        
        "About"      = $ctrl["NavAbout"]
    }
    $pageTitles = @{
        "Install"    = @("Install Applications",    "Select apps to install via winget")
        "Uninstall"  = @("Uninstall Applications",  "Remove winget-managed apps from your system")
        "AppUpdates" = @("App Updates",              "Apps with updates available - scanned at startup")
        "Tweaks"     = @("System Tweaks",            "Apply performance, privacy and UI optimisations")
        "Services"   = @("Windows Services",         "Manage and disable unnecessary background services")
        "Repair"     = @("Repair & Maintenance",     "Diagnose and fix common Windows issues")
        "Updates"    = @("Windows Updates",          "Check, install, pause or resume Windows updates")
        
        "About"      = @("About WinToolerV1",        "Version information and credits")
    }

    $navStyleActive   = $win.Resources["NavBtnActive"]   # kept for reference
    $navStyleInactive = $win.Resources["NavBtn"]              # kept for reference
    $script:CurrentPage = "Install"

    $setStatus = { param($msg, $color = "#444444")
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

    $win.Add_Loaded({
        # Apply startup theme choice
        & script:Apply-Theme $false

        # Winget status
        if ($global:WingetPath) {
            $ctrl["WingetDot"].Fill    = script:Brush "#00CC6A"
            $ctrl["WingetStatus"].Text = if ($S.ContainsKey("StatusReady")) { $S["StatusReady"] } else { "ready" }
        } else {
            $ctrl["WingetDot"].Fill    = script:Brush "#FC3E3E"
            $ctrl["WingetStatus"].Text = "not found"
            $ctrl["BtnInstall"].IsEnabled = $false
        }

        # Apply language strings to all named controls
        if ($ctrl["BtnSelectAll"])      { $ctrl["BtnSelectAll"].Content       = $S["BtnSelectAll"] }
        if ($ctrl["BtnDeselectAll"])    { $ctrl["BtnDeselectAll"].Content     = $S["BtnDeselectAll"] }
        if ($ctrl["BtnInstall"])        { $ctrl["BtnInstall"].Content         = $S["BtnInstall"] }
        if ($ctrl["BtnInstallCancel"])  { $ctrl["BtnInstallCancel"].Content   = $S["BtnInstallCancel"] }
        if ($ctrl["BtnRefreshUninstall"]) { $ctrl["BtnRefreshUninstall"].Content = $S["BtnRefreshUn"] }
        if ($ctrl["BtnUninstall"])      { $ctrl["BtnUninstall"].Content       = $S["BtnUninstall"] }
        if ($ctrl["BtnUpdateAll"])      { $ctrl["BtnUpdateAll"].Content       = $S["BtnUpdateAll"] }
        if ($ctrl["BtnUpdateSelected"]) { $ctrl["BtnUpdateSelected"].Content  = $S["BtnUpdateSel"] }
        if ($ctrl["BtnReCheckUpdates"]) { $ctrl["BtnReCheckUpdates"].Content  = $S["BtnReCheck"] }
        if ($ctrl["BtnCheckAll"])       { $ctrl["BtnCheckAll"].Content        = $S["BtnCheckAll"] }
        if ($ctrl["BtnUncheckAll"])     { $ctrl["BtnUncheckAll"].Content      = $S["BtnUncheckAll"] }
        if ($ctrl["BtnApplyTweaks"])    { $ctrl["BtnApplyTweaks"].Content     = $S["BtnApplyTweaks"] }
        if ($ctrl["BtnUndoTweaks"])     { $ctrl["BtnUndoTweaks"].Content      = $S["BtnUndoTweaks"] }
        if ($ctrl["BtnSvcDisable"])     { $ctrl["BtnSvcDisable"].Content      = $S["BtnSvcDisable"] }
        if ($ctrl["BtnSvcManual"])      { $ctrl["BtnSvcManual"].Content       = $S["BtnSvcManual"] }
        if ($ctrl["BtnSvcEnable"])      { $ctrl["BtnSvcEnable"].Content       = $S["BtnSvcEnable"] }
        if ($ctrl["BtnRunUpdates"])     { $ctrl["BtnRunUpdates"].Content      = $S["BtnRunUpdates"] }
        if ($ctrl["BtnPauseUpdates"])   { $ctrl["BtnPauseUpdates"].Content    = $S["BtnPauseUpdates"] }
        if ($ctrl["BtnResumeUpdates"])  { $ctrl["BtnResumeUpdates"].Content   = $S["BtnResumeUpdates"] }
        if ($ctrl["BtnOpenLog"])        { $ctrl["BtnOpenLog"].Content         = $S["BtnOpenLog"] }
        if ($ctrl["TplNone"])           { $ctrl["TplNone"].Content            = $S["TplNone"] }
        if ($ctrl["TplStandard"])       { $ctrl["TplStandard"].Content        = $S["TplStandard"] }
        if ($ctrl["TplMinimal"])        { $ctrl["TplMinimal"].Content         = $S["TplMinimal"] }
        if ($ctrl["TplHeavy"])          { $ctrl["TplHeavy"].Content           = $S["TplHeavy"] }

        # Nav button labels
        $navLabels = @{
            "NavInstall"="NavInstall"; "NavUninstall"="NavUninstall"
            "NavAppUpdates"="NavAppUpdates"; "NavTweaks"="NavTweaks"
            "NavServices"="NavServices"; "NavRepair"="NavRepair"
            "NavUpdates"="NavUpdates"; "NavAbout"="NavAbout"
        }
        # Page titles map
        $pageTitles["Install"]    = @($S["TitleInstall"],   $S["SubInstall"])
        $pageTitles["Uninstall"]  = @($S["TitleUninstall"], $S["SubUninstall"])
        $pageTitles["AppUpdates"] = @($S["TitleAppUpdates"],$S["SubAppUpdates"])
        $pageTitles["Tweaks"]     = @($S["TitleTweaks"],    $S["SubTweaks"])
        $pageTitles["Services"]   = @($S["TitleServices"],  $S["SubServices"])
        $pageTitles["Repair"]     = @($S["TitleRepair"],    $S["SubRepair"])
        $pageTitles["Updates"]    = @($S["TitleUpdates"],   $S["SubUpdates"])
        $pageTitles["DNS"]        = @("DNS Changer",        "Switch DNS servers for all active network adapters")
        $pageTitles["About"]      = @($S["TitleAbout"],     $S["SubAbout"])

        # Set initial page title
        $ctrl["PageTitle"].Text    = $S["TitleInstall"]
        $ctrl["PageSubtitle"].Text = $S["SubInstall"]
    })

    # Open log button
    $ctrl["BtnOpenLog"].Add_Click({
        if (Test-Path $global:LogFile) { Start-Process notepad.exe -ArgumentList $global:LogFile }
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
        $row.CornerRadius = New-Object Windows.CornerRadius(8)
        $row.Padding      = New-Object Windows.Thickness(12,9,12,9)
        $row.Margin       = New-Object Windows.Thickness(0,1,0,1)
        $row.Cursor       = [System.Windows.Input.Cursors]::Hand
        $row.Tag          = $app.Id

        $rg  = New-Object Windows.Controls.Grid
        $rc1 = New-Object Windows.Controls.ColumnDefinition; $rc1.Width = [Windows.GridLength]::Auto
        $rc2 = New-Object Windows.Controls.ColumnDefinition; $rc2.Width = [Windows.GridLength]::Auto
        $rc3 = New-Object Windows.Controls.ColumnDefinition
        $rc4 = New-Object Windows.Controls.ColumnDefinition; $rc4.Width = [Windows.GridLength]::Auto
        $rg.ColumnDefinitions.Add($rc1); $rg.ColumnDefinitions.Add($rc2)
        $rg.ColumnDefinitions.Add($rc3); $rg.ColumnDefinitions.Add($rc4)

        $cb = New-Object Windows.Controls.CheckBox
        $cb.IsChecked = $false; $cb.VerticalAlignment = "Center"; $cb.Tag = $app.Id
        [Windows.Controls.Grid]::SetColumn($cb, 0); $rg.Children.Add($cb) | Out-Null

        # macOS-style icon tile
        $tColor = if ($app.Color) { [Windows.Media.ColorConverter]::ConvertFromString($app.Color) } else { [Windows.Media.Color]::FromRgb(0,120,212) }
        $iconBd = New-Object Windows.Controls.Border
        $iconBd.Width = 38; $iconBd.Height = 38
        $iconBd.CornerRadius = New-Object Windows.CornerRadius(10)
        $iconBd.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(40,$tColor.R,$tColor.G,$tColor.B))
        $iconBd.BorderBrush  = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromArgb(70,$tColor.R,$tColor.G,$tColor.B))
        $iconBd.BorderThickness = New-Object Windows.Thickness(1)
        $iconBd.Margin       = New-Object Windows.Thickness(12,0,12,0)
        # Shine overlay grid
        $iconGrid = New-Object Windows.Controls.Grid
        $shine = New-Object Windows.Controls.Border
        $shine.Background = New-Object Windows.Media.LinearGradientBrush
        $shine.Background.StartPoint = New-Object Windows.Point(0,0)
        $shine.Background.EndPoint   = New-Object Windows.Point(0,1)
        $gs1 = New-Object Windows.Media.GradientStop; $gs1.Color = [Windows.Media.Color]::FromArgb(60,255,255,255); $gs1.Offset = 0
        $gs2 = New-Object Windows.Media.GradientStop; $gs2.Color = [Windows.Media.Color]::FromArgb(0,255,255,255);  $gs2.Offset = 0.5
        $shine.Background.GradientStops.Add($gs1); $shine.Background.GradientStops.Add($gs2)
        $shine.CornerRadius = New-Object Windows.CornerRadius(10,10,0,0)
        $iconTb = New-Object Windows.Controls.TextBlock
        $iconTb.Text = $app.Icon; $iconTb.FontSize = 16; $iconTb.FontWeight = [Windows.FontWeights]::Bold
        $iconTb.Foreground = New-Object Windows.Media.SolidColorBrush($tColor)
        $iconTb.HorizontalAlignment = "Center"; $iconTb.VerticalAlignment = "Center"
        $iconGrid.Children.Add($shine) | Out-Null
        $iconGrid.Children.Add($iconTb) | Out-Null
        $iconBd.Child = $iconGrid
        [Windows.Controls.Grid]::SetColumn($iconBd, 1); $rg.Children.Add($iconBd) | Out-Null

        $txSp = New-Object Windows.Controls.StackPanel; $txSp.VerticalAlignment = "Center"
        $nm = New-Object Windows.Controls.TextBlock; $nm.Text = $app.Name; $nm.FontSize = 13
        $nm.FontWeight = [Windows.FontWeights]::SemiBold; $nm.Foreground = script:Brush $script:T.Text1
        $ds = New-Object Windows.Controls.TextBlock; $ds.Text = $app.Description; $ds.FontSize = 11
        $ds.Foreground = script:Brush $script:T.Text3
        $ds.Margin = New-Object Windows.Thickness(0,2,0,0)
        $wid = New-Object Windows.Controls.TextBlock; $wid.Text = $app.Id; $wid.FontSize = 10
        $wid.Foreground = script:Brush $script:T.Text4
        $wid.Margin = New-Object Windows.Thickness(0,1,0,0)
        $txSp.Children.Add($nm) | Out-Null; $txSp.Children.Add($ds) | Out-Null; $txSp.Children.Add($wid) | Out-Null
        [Windows.Controls.Grid]::SetColumn($txSp, 2); $rg.Children.Add($txSp) | Out-Null

        $stBd = New-Object Windows.Controls.Border
        $stBd.CornerRadius = New-Object Windows.CornerRadius(12)
        $stBd.Padding = New-Object Windows.Thickness(10,3,10,3)
        $stBd.VerticalAlignment = "Center"; $stBd.Margin = New-Object Windows.Thickness(12,0,0,0)
        $stBd.Visibility = "Collapsed"
        $stTb = New-Object Windows.Controls.TextBlock; $stTb.FontSize = 10; $stTb.FontWeight = [Windows.FontWeights]::SemiBold
        $stBd.Child = $stTb
        [Windows.Controls.Grid]::SetColumn($stBd, 3); $rg.Children.Add($stBd) | Out-Null
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

            $badge   = $script:BadgeMap[$app.Id]
            $badgeTb = $badge.Child
            $badge.Visibility = "Visible"
            $badgeTb.Text = "Installing..."
            $badge.Background = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(30,60,100))
            $badgeTb.Foreground = [Windows.Media.Brushes]::White

            Write-Host "  [$i/$total] $($app.Name) ($($app.Id))" -ForegroundColor DarkGray -NoNewline

            $out  = & $global:WingetPath install --id $app.Id --silent --scope machine --locale en-US `
                    --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1
            $code = $LASTEXITCODE

            if ($code -eq -1978335138) {
                $out  = & $global:WingetPath install --id $app.Id --silent --scope user --locale en-US `
                        --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1
                $code = $LASTEXITCODE
            }

            Write-WTLog "winget $($app.Id) => exit $code"

            if ($code -eq 0) {
                Write-Host "  OK" -ForegroundColor Green
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(10,50,25))
                $badgeTb.Text       = "Installed"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(0,204,106))
                $ok++
            } elseif ($code -eq -1978335189) {
                Write-Host "  Already present" -ForegroundColor DarkYellow
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(30,25,10))
                $badgeTb.Text       = "Already present"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(180,140,0))
                $skip++
            } elseif ($code -eq -1978335216) {
                Write-Host "  Not available (no winget source match)" -ForegroundColor Red
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(50,10,10))
                $badgeTb.Text       = "Not found"
                $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(252,62,62))
                $fail++
            } else {
                Write-Host "  Failed (code $code)" -ForegroundColor Red
                $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(50,10,10))
                $badgeTb.Text       = "Failed"
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

    function script:Build-UninstallList {
        $ctrl["UninstallPanel"].Children.Clear()
        $script:UninstallMap = @{}

        if (-not $global:WingetPath) {
            $tb = New-Object Windows.Controls.TextBlock
            $tb.Text = "winget not available."; $tb.Foreground = script:Brush "#FC3E3E"
            $ctrl["UninstallPanel"].Children.Add($tb) | Out-Null
            return
        }

        $ctrl["UninstallCount"].Text = "Loading..."
        $win.Dispatcher.Invoke([action]{}, "Render")

        Write-Host "  [Uninstall] Querying winget list..." -ForegroundColor DarkGray
        $raw = & $global:WingetPath list --disable-interactivity 2>&1
        $inTable = $false
        $entries = @()
        foreach ($line in $raw) {
            if ($line -match 'Name\s+Id\s+Version') { $inTable = $true; continue }
            if (-not $inTable) { continue }
            if ($line -match '^[-\s]+$' -or $line -notmatch '\S') { continue }
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 2) {
                $nm = $parts[0].Trim()
                $id = $parts[1].Trim()
                $vr = if ($parts.Count -ge 3) { $parts[2].Trim() } else { "" }
                if ($nm -and $id -and $id -notmatch '^[{<]') {
                    $entries += [pscustomobject]@{ Name=$nm; Id=$id; Version=$vr }
                }
            }
        }

        $searchTxt = $ctrl["UninstallSearch"].Text.Trim()
        $filtered  = if ($searchTxt) { $entries | Where-Object { $_.Name -like "*$searchTxt*" -or $_.Id -like "*$searchTxt*" } } else { $entries }

        $ctrl["UninstallCount"].Text = "$($filtered.Count) apps installed"

        foreach ($entry in ($filtered | Sort-Object Name)) {
            $row = New-Object Windows.Controls.Border
            $row.Background   = script:Brush $script:T.CardBG
            $row.CornerRadius = New-Object Windows.CornerRadius(8)
            $row.Padding      = New-Object Windows.Thickness(14,10,14,10)
            $row.Margin       = New-Object Windows.Thickness(0,0,0,4)
            $row.BorderBrush  = script:Brush $script:T.CardBorder
            $row.BorderThickness = New-Object Windows.Thickness(1)

            $rg = New-Object Windows.Controls.Grid
            $rc1 = New-Object Windows.Controls.ColumnDefinition; $rc1.Width = [Windows.GridLength]::Auto
            $rc2 = New-Object Windows.Controls.ColumnDefinition
            $rc3 = New-Object Windows.Controls.ColumnDefinition; $rc3.Width = [Windows.GridLength]::Auto
            $rg.ColumnDefinitions.Add($rc1); $rg.ColumnDefinitions.Add($rc2); $rg.ColumnDefinitions.Add($rc3)

            $cb = New-Object Windows.Controls.CheckBox
            $cb.VerticalAlignment = "Center"; $cb.Tag = $entry.Id
            [Windows.Controls.Grid]::SetColumn($cb, 0); $rg.Children.Add($cb) | Out-Null

            $txSp = New-Object Windows.Controls.StackPanel; $txSp.Margin = New-Object Windows.Thickness(14,0,0,0); $txSp.VerticalAlignment = "Center"
            $nm2 = New-Object Windows.Controls.TextBlock; $nm2.Text = $entry.Name; $nm2.FontSize = 13
            $nm2.FontWeight = [Windows.FontWeights]::SemiBold; $nm2.Foreground = script:Brush $script:T.Text1
            $id2 = New-Object Windows.Controls.TextBlock; $id2.Text = $entry.Id; $id2.FontSize = 10
            $id2.Foreground = script:Brush $script:T.Text4
            $txSp.Children.Add($nm2) | Out-Null; $txSp.Children.Add($id2) | Out-Null
            [Windows.Controls.Grid]::SetColumn($txSp, 1); $rg.Children.Add($txSp) | Out-Null

            $verTb = New-Object Windows.Controls.TextBlock; $verTb.Text = $entry.Version; $verTb.FontSize = 11
            $verTb.Foreground = script:Brush $script:T.Text3
            $verTb.VerticalAlignment = "Center"
            [Windows.Controls.Grid]::SetColumn($verTb, 2); $rg.Children.Add($verTb) | Out-Null

            $row.Child = $rg
            $ctrl["UninstallPanel"].Children.Add($row) | Out-Null
            $script:UninstallMap[$entry.Id] = @{ CB=$cb; Name=$entry.Name }

            $cb.Add_Checked({
                $n = ($script:UninstallMap.Values | Where-Object { $_.CB.IsChecked }).Count
                $ctrl["UninstallSelTxt"].Text     = "$n selected"
                $ctrl["BtnUninstall"].IsEnabled   = ($n -gt 0)
            })
            $cb.Add_Unchecked({
                $n = ($script:UninstallMap.Values | Where-Object { $_.CB.IsChecked }).Count
                $ctrl["UninstallSelTxt"].Text     = "$n selected"
                $ctrl["BtnUninstall"].IsEnabled   = ($n -gt 0)
            })
        }
    }

    $ctrl["NavUninstall"].Add_Click({ & script:Build-UninstallList })
    $ctrl["BtnRefreshUninstall"].Add_Click({ & script:Build-UninstallList })
    $ctrl["UninstallSearch"].Add_TextChanged({ & script:Build-UninstallList })

    $ctrl["BtnUninstall"].Add_Click({
        $toRemove = $script:UninstallMap.GetEnumerator() | Where-Object { $_.Value.CB.IsChecked }
        $total = @($toRemove).Count
        if ($total -eq 0) { return }
        $ok = 0
        Write-Host ""
        Write-Host "  --[ Uninstalling $total Apps ]" -ForegroundColor Cyan
        foreach ($kv in $toRemove) {
            $id   = $kv.Key
            $name = $kv.Value.Name
            Write-Host "  Removing $name..." -ForegroundColor DarkGray -NoNewline
            $out  = & $global:WingetPath uninstall --id $id --silent --accept-source-agreements --disable-interactivity 2>&1
            $code = $LASTEXITCODE
            Write-WTLog "winget uninstall $id => exit $code"
            if ($code -eq 0) { Write-Host " OK" -ForegroundColor Green; $ok++ }
            else              { Write-Host " Failed (code $code)" -ForegroundColor Red }
        }
        Write-Host "  Uninstall done: $ok of $total removed" -ForegroundColor Cyan
        & script:Build-UninstallList
    })

    # ================================================================
    #  BUILD APP UPDATES TAB
    # ================================================================
    $script:UpdateCBMap = @{}

    function script:Build-AppUpdateList {
        $ctrl["AppUpdatePanel"].Children.Clear()
        $script:UpdateCBMap = @{}
        $ctrl["UpdateStatusTxt"].Text = "Loading..."

        $updMap = $global:AppUpdates
        if ($updMap.Count -eq 0) {
            $tb = New-Object Windows.Controls.TextBlock
            $tb.Text = "No updates found at startup. Press Re-Check to scan again."
            $tb.Foreground = script:Brush $script:T.Text3
            $tb.FontSize = 13; $tb.Margin = New-Object Windows.Thickness(0,20,0,0)
            $ctrl["AppUpdatePanel"].Children.Add($tb) | Out-Null
            $ctrl["UpdateStatusTxt"].Text = "All up to date"
            $ctrl["BtnUpdateAll"].IsEnabled      = $false
            $ctrl["BtnUpdateSelected"].IsEnabled = $false
            return
        }

        foreach ($kv in ($updMap.GetEnumerator() | Sort-Object Key)) {
            $id  = $kv.Key
            $cur = $kv.Value.Current
            $avl = $kv.Value.Available

            $row = New-Object Windows.Controls.Border
            $row.Background   = script:Brush $script:T.CardBG
            $row.CornerRadius = New-Object Windows.CornerRadius(8)
            $row.Padding      = New-Object Windows.Thickness(14,10,14,10)
            $row.Margin       = New-Object Windows.Thickness(0,0,0,4)
            $row.BorderBrush  = script:Brush $script:T.CardBorder
            $row.BorderThickness = New-Object Windows.Thickness(1)

            $rg = New-Object Windows.Controls.Grid
            $rc1 = New-Object Windows.Controls.ColumnDefinition; $rc1.Width = [Windows.GridLength]::Auto
            $rc2 = New-Object Windows.Controls.ColumnDefinition
            $rc3 = New-Object Windows.Controls.ColumnDefinition; $rc3.Width = [Windows.GridLength]::Auto
            $rg.ColumnDefinitions.Add($rc1); $rg.ColumnDefinitions.Add($rc2); $rg.ColumnDefinitions.Add($rc3)

            $cb = New-Object Windows.Controls.CheckBox
            $cb.IsChecked = $true; $cb.VerticalAlignment = "Center"; $cb.Tag = $id
            [Windows.Controls.Grid]::SetColumn($cb, 0); $rg.Children.Add($cb) | Out-Null

            $txSp = New-Object Windows.Controls.StackPanel; $txSp.Margin = New-Object Windows.Thickness(14,0,0,0); $txSp.VerticalAlignment = "Center"
            $nm2  = New-Object Windows.Controls.TextBlock; $nm2.Text = $id; $nm2.FontSize = 13
            $nm2.FontWeight = [Windows.FontWeights]::SemiBold; $nm2.Foreground = script:Brush $script:T.Text1
            $vr2  = New-Object Windows.Controls.TextBlock; $vr2.Text = "$cur  ->  $avl"; $vr2.FontSize = 11
            $vr2.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(100,180,100))
            $txSp.Children.Add($nm2) | Out-Null; $txSp.Children.Add($vr2) | Out-Null
            [Windows.Controls.Grid]::SetColumn($txSp, 1); $rg.Children.Add($txSp) | Out-Null

            $badge = New-Object Windows.Controls.Border
            $badge.Background   = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(10,40,15))
            $badge.CornerRadius = New-Object Windows.CornerRadius(10); $badge.Padding = New-Object Windows.Thickness(8,3,8,3)
            $badge.VerticalAlignment = "Center"
            $badgeTb = New-Object Windows.Controls.TextBlock; $badgeTb.Text = $avl; $badgeTb.FontSize = 11
            $badgeTb.Foreground = New-Object Windows.Media.SolidColorBrush([Windows.Media.Color]::FromRgb(0,200,80))
            $badge.Child = $badgeTb
            [Windows.Controls.Grid]::SetColumn($badge, 2); $rg.Children.Add($badge) | Out-Null

            $row.Child = $rg
            $ctrl["AppUpdatePanel"].Children.Add($row) | Out-Null
            $script:UpdateCBMap[$id] = $cb
        }

        $ctrl["UpdateStatusTxt"].Text        = "$($updMap.Count) update(s) available"
        $ctrl["BtnUpdateAll"].IsEnabled      = $true
        $ctrl["BtnUpdateSelected"].IsEnabled = $true

        # Show badge in nav
        $ctrl["UpdateBadge"].Visibility    = "Visible"
        $ctrl["UpdateBadgeTxt"].Text       = "$($updMap.Count)"
    }

    $ctrl["NavAppUpdates"].Add_Click({ & script:Build-AppUpdateList })

    $doUpdate = {
        param([bool]$all)
        $ids = if ($all) {
            @($script:UpdateCBMap.Keys)
        } else {
            @($script:UpdateCBMap.GetEnumerator() | Where-Object { $_.Value.IsChecked } | ForEach-Object { $_.Key })
        }
        $count = @($ids).Count
        if ($count -eq 0) { return }
        $ctrl["BtnUpdateAll"].IsEnabled      = $false
        $ctrl["BtnUpdateSelected"].IsEnabled = $false
        $ok = 0; $skip = 0; $fail = 0

        Write-Host ""
        Write-Host "  --[ Updating $count Apps ]" -ForegroundColor Cyan

        foreach ($id in $ids) {
            Write-Host "  Updating $id..." -ForegroundColor DarkGray -NoNewline

            # Find the row badge in the update panel and mark it
            $rowBadge = $script:UpdateBadgeMap[$id]

            $out  = & $global:WingetPath upgrade --id $id --silent `
                    --accept-package-agreements --accept-source-agreements `
                    --disable-interactivity 2>&1
            $code = $LASTEXITCODE
            Write-WTLog "winget upgrade $id => exit $code"

            switch ($code) {
                0 {
                    Write-Host "  OK" -ForegroundColor Green
                    $ok++
                    $global:AppUpdates.Remove($id)
                }
                -1978335189 {
                    # "No applicable update found" - winget version mismatch with installed
                    # Try with --force to override version pinning
                    Write-Host "  Retrying with --force..." -ForegroundColor DarkYellow -NoNewline
                    $out2  = & $global:WingetPath upgrade --id $id --silent --force `
                             --accept-package-agreements --accept-source-agreements `
                             --disable-interactivity 2>&1
                    $code2 = $LASTEXITCODE
                    Write-WTLog "winget upgrade $id --force => exit $code2"
                    if ($code2 -eq 0) {
                        Write-Host "  OK" -ForegroundColor Green
                        $ok++
                        $global:AppUpdates.Remove($id)
                    } else {
                        Write-Host "  Already current (winget/installer mismatch)" -ForegroundColor DarkYellow
                        $skip++
                        $global:AppUpdates.Remove($id)
                    }
                }
                -1978335230 {
                    # Hash mismatch - clear winget cache and retry once
                    Write-Host "  Hash mismatch - clearing cache and retrying..." -ForegroundColor DarkYellow -NoNewline
                    $cacheDir = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache"
                    if (Test-Path $cacheDir) { Remove-Item "$cacheDir\*" -Recurse -Force -ErrorAction SilentlyContinue }
                    $out2  = & $global:WingetPath upgrade --id $id --silent `
                             --accept-package-agreements --accept-source-agreements `
                             --disable-interactivity 2>&1
                    $code2 = $LASTEXITCODE
                    Write-WTLog "winget upgrade $id (after cache clear) => exit $code2"
                    if ($code2 -eq 0) {
                        Write-Host "  OK" -ForegroundColor Green
                        $ok++
                        $global:AppUpdates.Remove($id)
                    } else {
                        Write-Host "  Failed after retry (code $code2)" -ForegroundColor Red
                        $fail++
                    }
                }
                -1978335212 {
                    # Hash mismatch variant
                    Write-Host "  Installer hash mismatch - skipped (try again later)" -ForegroundColor DarkYellow
                    $fail++
                }
                default {
                    Write-Host "  Failed (code $code)" -ForegroundColor Red
                    $fail++
                }
            }
            $win.Dispatcher.Invoke([action]{}, "Render")
        }

        Write-Host ""
        Write-Host "  Update done: $ok updated  $skip already current  $fail failed" -ForegroundColor Cyan
        Write-WTLog "Update complete: ok=$ok skip=$skip fail=$fail"
        $ctrl["BtnUpdateAll"].IsEnabled      = $true
        $ctrl["BtnUpdateSelected"].IsEnabled = $true
        & script:Build-AppUpdateList
    }

    $ctrl["BtnUpdateAll"].Add_Click({      & $doUpdate $true  })
    $ctrl["BtnUpdateSelected"].Add_Click({ & $doUpdate $false })

    $ctrl["BtnReCheckUpdates"].Add_Click({
        if (-not $global:WingetPath) { return }
        $ctrl["UpdateStatusTxt"].Text = "Scanning..."
        $global:AppUpdates = @{}
        $raw = & $global:WingetPath upgrade --include-unknown --disable-interactivity 2>&1
        $inTable = $false
        foreach ($line in $raw) {
            if ($line -match 'Name\s+Id\s+Version\s+Available') { $inTable = $true; continue }
            if (-not $inTable) { continue }
            if ($line -match '^[-\s]+$') { continue }
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 3) {
                $id  = ($parts | Select-Object -Index 1).Trim()
                $cur = ($parts | Select-Object -Index 2).Trim()
                $avl = if ($parts.Count -ge 4) { ($parts | Select-Object -Index 3).Trim() } else { "newer" }
                if ($id -and $avl -and $avl -ne "Unknown" -and $id -notmatch 'pinned') {
                    $global:AppUpdates[$id] = @{ Current=$cur; Available=$avl }
                }
            }
        }
        & script:Build-AppUpdateList
    })

    # Pre-populate update list from CLI scan
    if ($global:AppUpdates.Count -gt 0) {
        $ctrl["UpdateBadge"].Visibility = "Visible"
        $ctrl["UpdateBadgeTxt"].Text    = "$($global:AppUpdates.Count)"
    }

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
        if ($n -eq 0) { & $setStatus "No tweaks selected." "#FFB900"; return }
        & $setStatus "Applying $n tweaks..."
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
        & $setStatus "Done! Applied $ok of $n tweaks. Reboot may be needed." "#00CC6A"
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
        & $setStatus "Service changes applied." "#00CC6A"
    }

    $ctrl["BtnSvcDisable"].Add_Click({ & $svcAction "Disable" })
    $ctrl["BtnSvcManual"].Add_Click({  & $svcAction "Manual"  })
    $ctrl["BtnSvcEnable"].Add_Click({  & $svcAction "Enable"  })

    # ================================================================
    #  REPAIR TAB - async SFC/DISM with live output
    # ================================================================
    $appendRepair = {
        param([string]$text)
        $ctrl["RepairOutput"].AppendText($text + "`n")
        $ctrl["RepairOutput"].ScrollToEnd()
        Write-Host "  $text" -ForegroundColor DarkGray
    }

    $ctrl["BtnSFC"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        $ctrl["RepairSpinner"].Visibility = "Visible"
        & $appendRepair "Running SFC /scannow ..."
        & $appendRepair "(This may take 5-15 minutes. GUI remains responsive.)"
        & $appendRepair ""
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
            & $appendRepair ""
            & $appendRepair "SFC complete."
            & $appendRepair "Running DISM RestoreHealth ..."
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
        & $appendRepair ""
        & $appendRepair "SFC + DISM complete."
        Write-WTLog "SFC+DISM complete"
    })

    $ctrl["BtnClearTemp"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $appendRepair "Clearing temp files..."
        $result = Clear-TempFiles
        & $appendRepair $result
        & $setStatus $result "#00CC6A"
    })

    $ctrl["BtnFlushDNS"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $appendRepair "Flushing DNS cache..."
        $result = Invoke-FlushDNS
        & $appendRepair $result
        & $setStatus "DNS flushed." "#00CC6A"
    })

    $ctrl["BtnWsReset"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $appendRepair "Resetting Windows Store..."
        wsreset.exe 2>&1 | Out-Null
        & $appendRepair "Windows Store reset complete."
        & $setStatus "Windows Store reset." "#00CC6A"
    })

    $ctrl["BtnRestorePoint"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $appendRepair "Creating restore point..."
        $result = New-RestorePoint -Label "WinToolerV1 Manual"
        & $appendRepair $result
        & $setStatus $result "#00CC6A"
    })

    $ctrl["BtnNetReset"].Add_Click({
        $ctrl["RepairOutput"].Clear()
        & $appendRepair "Resetting network stack..."
        $result = Reset-NetworkStack
        & $appendRepair $result
        & $setStatus "Network reset done. Reboot required." "#FFB900"
    })

    # ================================================================
    #  WINDOWS UPDATES TAB
    # ================================================================
    $ctrl["BtnRunUpdates"].Add_Click({
        $ctrl["UpdateOutput"].Text = "Checking for Windows Updates...`n"
        try {
            Import-Module PSWindowsUpdate -ErrorAction Stop
            $updates = Get-WindowsUpdate -MicrosoftUpdate -AcceptAll -ErrorAction Stop
            if ($updates.Count -eq 0) {
                $ctrl["UpdateOutput"].AppendText("No updates available. System is up to date.`n")
            } else {
                $ctrl["UpdateOutput"].AppendText("Found $($updates.Count) update(s).`n`n")
                foreach ($u in $updates) {
                    $ctrl["UpdateOutput"].AppendText("  Installing: $($u.Title)`n")
                    $win.Dispatcher.Invoke([action]{}, "Render")
                }
                Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot:$false -ErrorAction Stop | Out-Null
                $ctrl["UpdateOutput"].AppendText("`nUpdates installed. Reboot may be required.`n")
            }
        } catch {
            $ctrl["UpdateOutput"].AppendText("Error: $_`n")
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
    #  DNS CHANGER (inspired by winutil dns.json / Set-WinUtilDNS)
    # ================================================================
    $dnsList = [ordered]@{
        "Default (DHCP)"        = @{ Primary=""; Secondary=""; Color="#5A5A5A"; Desc="Restore ISP default via DHCP" }
        "Google"                = @{ Primary="8.8.8.8"; Secondary="8.8.4.4"; Color="#0067C0"; Desc="8.8.8.8 / 8.8.4.4" }
        "Cloudflare"            = @{ Primary="1.1.1.1"; Secondary="1.0.0.1"; Color="#F38020"; Desc="1.1.1.1 / 1.0.0.1  Fastest" }
        "Cloudflare Malware"    = @{ Primary="1.1.1.2"; Secondary="1.0.0.2"; Color="#D83B01"; Desc="1.1.1.2 / 1.0.0.2  Blocks malware" }
        "OpenDNS"               = @{ Primary="208.67.222.222"; Secondary="208.67.220.220"; Color="#00A4A6"; Desc="208.67.222.222 / 220.220" }
        "Quad9"                 = @{ Primary="9.9.9.9"; Secondary="149.112.112.112"; Color="#7B3F9E"; Desc="9.9.9.9 / 149.112.112.112  Security" }
        "AdGuard"               = @{ Primary="94.140.14.14"; Secondary="94.140.15.15"; Color="#67B279"; Desc="94.140.14.14 / 15.15  Ad block" }
        "NextDNS"               = @{ Primary="45.90.28.0"; Secondary="45.90.30.0"; Color="#003EFF"; Desc="45.90.28.0 / 30.0  Customizable" }
        "Comodo"                = @{ Primary="8.26.56.26"; Secondary="8.20.247.20"; Color="#CC0000"; Desc="8.26.56.26 / 20.247.20  Security" }
        "Level3"                = @{ Primary="4.2.2.1"; Secondary="4.2.2.2"; Color="#444444"; Desc="4.2.2.1 / 4.2.2.2  Reliable" }
    }

    function script:DNSLog { param([string]$msg)
        $ctrl["DNSOutput"].AppendText("$msg`n")
        $ctrl["DNSOutput"].ScrollToEnd()
    }

    # Build DNS provider cards
    foreach ($dnsName in $dnsList.Keys) {
        $dn    = $dnsName
        $dInfo = $dnsList[$dn]

        $card = New-Object Windows.Controls.Border
        $card.Width           = 160
        $card.Height          = 90
        $card.Margin          = New-Object Windows.Thickness(0,0,12,12)
        $card.Background      = [Windows.Media.Brushes]::White
        $card.CornerRadius    = New-Object Windows.CornerRadius(10)
        $card.BorderBrush     = script:Brush "#E5E5E5"
        $card.BorderThickness = New-Object Windows.Thickness(1)
        $card.Cursor          = [Windows.Input.Cursors]::Hand

        # Inner layout
        $inner = New-Object Windows.Controls.Grid
        $card.Child = $inner

        $accentBar = New-Object Windows.Controls.Border
        $accentBar.Width           = 3
        $accentBar.HorizontalAlignment = "Left"
        $accentBar.Background      = script:Brush $dInfo.Color
        $accentBar.CornerRadius    = New-Object Windows.CornerRadius(10,0,0,10)
        [void]$inner.Children.Add($accentBar)

        $sp = New-Object Windows.Controls.StackPanel
        $sp.Margin = New-Object Windows.Thickness(16,10,10,10)
        [void]$inner.Children.Add($sp)

        $nameBlock = New-Object Windows.Controls.TextBlock
        $nameBlock.Text       = $dn
        $nameBlock.FontSize   = 12
        $nameBlock.FontWeight = [Windows.FontWeights]::SemiBold
        $nameBlock.Foreground = script:Brush "#1A1A1A"
        $nameBlock.TextTrimming = "CharacterEllipsis"
        [void]$sp.Children.Add($nameBlock)

        $descBlock = New-Object Windows.Controls.TextBlock
        $descBlock.Text         = $dInfo.Desc
        $descBlock.FontSize     = 10
        $descBlock.Foreground   = script:Brush "#888888"
        $descBlock.TextWrapping = "Wrap"
        $descBlock.Margin       = New-Object Windows.Thickness(0,3,0,0)
        [void]$sp.Children.Add($descBlock)

        # Hover effects
        $card.Add_MouseEnter({ $this.BorderBrush = script:Brush "#0067C0"; $this.Background = script:Brush "#F0F6FF" })
        $card.Add_MouseLeave({ $this.BorderBrush = script:Brush "#E5E5E5"; $this.Background = [Windows.Media.Brushes]::White })

        # Click to apply DNS
        $card.Add_MouseLeftButtonUp({
            $info = $dnsList[$dn]
            $ctrl["DNSOutput"].Text = ""
            $ctrl["DNSStatusTxt"].Text = " Applying $dn..."
            $ctrl["DNSStatusTxt"].Visibility = "Visible"
            & script:DNSLog "Applying DNS: $dn"

            try {
                $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
                if (-not $adapters) {
                    & script:DNSLog "No active network adapters found."
                } else {
                    foreach ($adapter in $adapters) {
                        if ($dn -eq "Default (DHCP)") {
                            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses -EA Stop
                            & script:DNSLog "  Adapter '$($adapter.Name)': reset to DHCP"
                        } else {
                            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex `
                                -ServerAddresses ($info.Primary, $info.Secondary) -EA Stop
                            & script:DNSLog "  Adapter '$($adapter.Name)': $($info.Primary) / $($info.Secondary)"
                        }
                    }
                    & script:DNSLog "Done. DNS set to $dn on $($adapters.Count) adapter(s)."
                    & script:DNSLog "Tip: run 'ipconfig /flushdns' to clear resolver cache."
                    $ctrl["DNSStatusTxt"].Text = " $dn applied"
                }
            } catch {
                & script:DNSLog "ERROR: $_"
                $ctrl["DNSStatusTxt"].Text = " Error applying DNS"
            }
        }.GetNewClosure())

        [void]$ctrl["DNSCardPanel"].Children.Add($card)
    }


    # ================================================================
    #  SHOW WINDOW
    # ================================================================
    & $setStatus "Ready - $($global:AppCatalog.Count) apps | $($global:TweaksCatalog.Count) tweaks | $($global:ServicesList.Count) services"
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
    Background="#F0F2F5"
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
      <Border Width="64" Height="64" CornerRadius="16" Background="#0067C0"
              HorizontalAlignment="Center" Margin="0,0,0,14">
        <Grid>
          <Ellipse Width="24" Height="24" Fill="White" Opacity="0.12"
                   HorizontalAlignment="Left" VerticalAlignment="Top" Margin="8,7,0,0"/>
          <TextBlock Text="W" FontSize="30" FontWeight="Black" Foreground="White"
                     HorizontalAlignment="Center" VerticalAlignment="Center"/>
        </Grid>
      </Border>
      <TextBlock Text="WinToolerV1" FontSize="26" FontWeight="Bold"
                 Foreground="#1A1A1A" HorizontalAlignment="Center"/>
      <TextBlock Text="v0.6 BETA  by ErickP (Eperez98)" FontSize="12"
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
