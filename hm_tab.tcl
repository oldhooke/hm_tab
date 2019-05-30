# HWVERSION_2017.1_Apr 12 2017_22:30:32
#################################################################
# File      : hm_tab.tcl
# Date      : June 7, 2007
# Created by: Liu Dongliang
# Purpose   : Creates a GUI to help manage test gauges
#################################################################
package require hwt;
package require hwtk;

catch {namespace delete ::hm::MyTab }

namespace eval ::hm::MyTab {
    variable m_title "MyTab";
	variable m_recess ".m_MyTab";
	variable m_radius 10;
	variable m_reviewrange 100;
	variable m_InReview 0;
	variable m_file ""
}

#################################################################
proc ::hm::MyTab::Answer { question type } {
	return [tk_messageBox \
			-title "Question"\
			-icon info \
			-message "$question" \
			-type $type]
}
#################################################################
proc ::hm::MyTab::ValidateName { name } {
	return [ regexp {^[a-zA-Z]+[0-9a-zA-Z_-]*$} $name ] 
}

#################################################################
proc ::hm::MyTab::DialogCreate { args } {
    # Purpose:  Creates the tab and the master frame
    # Args:
    # Returns:  1 for success. 0 if the tab already exists.
    # Notes:

    variable m_recess;
    variable m_title;

    set alltabs [hm_framework getalltabs];

    if {[lsearch $alltabs $m_title] != -1} {
        hm_framework activatetab "$m_title";

        return 0;
    } else {
        catch {destroy $m_recess};

        set m_recess [frame $m_recess -padx 7 -pady 7];

        hm_framework addtab "$m_title" $m_recess ::hm::MyTab::Resize ::hm::MyTab::TearDownWindow;

        ::hwt::AddPadding $m_recess -side top height [hwt::DluHeight 4] width [hwt::DluWidth 0];

        return 1;
    }
}

#################################################################
proc ::hm::MyTab::Resize { args } {
    # Purpose:  Resize the tab
    # Args:
    # Returns:  Size to resize the tab to
    # Notes:

    return 358;
}

#################################################################
proc ::hm::MyTab::TearDownWindow { flag args } {
    # Purpose:  Destroy the tab and frame when the GUI is closed.
    # Args:     flag - hm_framework flag that is passed to tell
    #           the proc when it is being called.
    # Returns:
    # Notes:

    variable m_recess;
    variable m_title;

    if {$flag == "after_deactivate"} {
        catch {::hm::MyTab::UnsetCallbacks};
        catch {destroy $m_recess };
        hm_framework removetab "$m_title";

        focus -force $::HM_Framework::p_hm_container;
    }
}

#################################################################
proc ::hm::MyTab::SetCallbacks { args } {
    # Purpose:  Defines the callbacks
    # Args:
    # Returns:
    # Notes:

    ::hwt::AddCallback *readfile ::hm::MyTab::New;
    ::hwt::AddCallback *deletemodel ::hm::MyTab::New;
	
    ::hwt::AddCallback *deletemark ::hm::MyTab::RemoveSystem before
}

#################################################################
proc ::hm::MyTab::UnsetCallbacks { args } {
    # Purpose:  Undefines the callbacks when the tab is closed
    # Args:
    # Returns:
    # Notes:

    ::hwt::RemoveCallback *readfile ::hm::MyTab::New;
    ::hwt::RemoveCallback *deletemodel ::hm::MyTab::New;
	
    ::hwt::RemoveCallback *deletemark ::hm::MyTab::RemoveSystem;
}

#################################################################
proc ::hm::MyTab::ElementCentroid { args } {
	*createmarkpanel elems 1 "Select Elements to create nodes at the centroid"
	set elemlist [hm_getmark elems 1]
	*clearmark elems 1
	
	foreach elemid $elemlist {
		foreach {x y z} [hm_entityinfo centroid elems $elemid] {break};
		eval *createnode $x $y $z 0 0 0
	}
}
#################################################################
proc ::hm::MyTab::DotProduct {vector1 vector2} {
    set dot 0
    
    set a1 [lindex $vector1 0]
    set a2 [lindex $vector1 1]
    set a3 [lindex $vector1 2]
        
    set b1 [lindex $vector2 0]
    set b2 [lindex $vector2 1]
    set b3 [lindex $vector2 2]
    
    set dot [expr {$a1*$b1+$a2*$b2+$a3*$b3}]
    
    return $dot
}

proc ::hm::MyTab::AddVector { vector1 vector2 } {
    set a1 [lindex $vector1 0]
    set a2 [lindex $vector1 1]
    set a3 [lindex $vector1 2]
    
    set b1 [lindex $vector2 0]
    set b2 [lindex $vector2 1]
    set b3 [lindex $vector2 2]
    
    set c1 [expr $a1 + $b1]
    set c2 [expr $a2 + $b2]
    set c3 [expr $a3 + $b3]
    
    return [list $c1 $c2 $c3]
}

proc ::hm::MyTab::ScaleVector { vector1 alph } {
    set a1 [lindex $vector1 0]
    set a2 [lindex $vector1 1]
    set a3 [lindex $vector1 2]
    
    set c1 [expr $a1 * $alph]
    set c2 [expr $a2 * $alph]
    set c3 [expr $a3 * $alph]
    
    return [list $c1 $c2 $c3]
}

#################################################################
proc ::hm::MyTab::ClearMark {entity mark} {

    *clearmark $entity $mark
    hm_markclear $entity $mark 0
}

proc ::hm::MyTab::GetElementCentroid {elemid} {
    set centroids [list]
    
	foreach elem $elemid {
		if {[catch {
			lappend centroids [hm_entityinfo centroid elements $elem]} err]} {
			return 0
		}
	}
	return $centroids	
}

proc ::hm::MyTab::GetElementNormal {elem} {
	if {[catch {
		set x [hm_getentityvalue elements $elem "normalx" 0]
		set y [hm_getentityvalue elements $elem "normaly" 0]
		set z [hm_getentityvalue elements $elem "normalz" 0]
		} err ] } {
		return 0
	}	
	return [list $x $y $z]
}

proc ::hm::MyTab::FindClosestCentroid {x y z elems} {
    
    set elemid 0
    set index 0
    set mindistance 9999999.9
    
    if {[set centroids [ GetElementCentroid $elems ]] == 0} {
        return 0
    }
    
    foreach centroid $centroids {
        set thisX [lindex $centroid 0]
        set thisY [lindex $centroid 1]
        set thisZ [lindex $centroid 2]
        set distance [expr sqrt( \
	    ($x-$thisX)*($x-$thisX) + \
 	    ($y-$thisY)*($y-$thisY) + \
	    ($z-$thisZ)*($z-$thisZ))]
	    
		if {$distance < $mindistance} {
			set mindistance $distance
			set elemid [lindex $elems $index]
		}
	
		incr index
    }
    
    return $elemid
}

proc ::hm::MyTab::GetShellElements {elemid} {

    set elems [list]
    
    foreach elem $elemid {
        if {[catch {
            set etype [hm_getentityvalue elements $elem "config" 0] } err]} {
            return 0
        }
         
        if {$etype == "104" || $etype == "103"} {
            lappend elems $elem
        }
    }
    return $elems
}

proc ::hm::MyTab::GetClosestElement {x y z r } {
	ClearMark elements 1
	*createmark elems 1 "by sphere" $x $y $z $r inside 0 1 0
	set elems [ hm_getmark elems 1 ]
	
	set shell_elems [ GetShellElements $elems ]
	set elem_id [ FindClosestCentroid  $x $y $z $shell_elems ]
	return $elem_id
}

proc ::hm::MyTab::result_layer { elem system } {
	set e_normal [ GetElementNormal $elem ]
	set sys_z [ hm_getvalue systems id=$system dataname=zaxis ]
	set ans [ DotProduct $e_normal $sys_z ]
	if { $ans < 0 } {
		return "Bottom"
	} else {
		return "Top"
	}
}

#################################################################
proc ::hm::MyTab::Main { args } {
    # Purpose:  Creates the GUI and calls the routine to populate
    #           the table.
    # Args:
    # Returns:
    # Notes:
	
    variable m_recess;
	variable m_radius;
	variable m_reviewrange;
	variable m_width 12;
    variable m_split;
    variable m_tree;
    variable m_pa;
	
    # Create the GUI
    if [::hm::MyTab::DialogCreate] {
        # Create the frame1
		set frame1 [labelframe $m_recess.frame1 -text "Parameter" ];
        pack $frame1 -side top -anchor nw -fill x ;
			::hwtk::label $frame1.l1 -text "search radius:"
			::hwtk::entry $frame1.e1 -inputtype double -textvariable [namespace current]::m_radius
			grid $frame1.l1 $frame1.e1 -sticky w -pady 2 -padx 5
			grid configure $frame1.e1 -sticky ew
			
			::hwtk::label $frame1.l2 -text "review range:"
			::hwtk::entry $frame1.e2 -inputtype double -textvariable [namespace current]::m_reviewrange
			grid $frame1.l2 $frame1.e2 -sticky w -pady 2 -padx 5
			grid configure $frame1.e2 -sticky ew
			
			grid columnconfigure $frame1 1  -weight 1
			
		# Create the frame2
		set frame2 [labelframe $m_recess.frame2 -text "Command" ];
        pack $frame2 -side top -anchor nw -fill x ;
			::hwtk::toolbutton $frame2.new -image [hwtk::image cache fileNew-24.png] -help "New" -command { ::hm::MyTab::New } 
			::hwtk::toolbutton $frame2.open -image [hwtk::image cache fileOpen-24.png] -help "Open" -command { ::hm::MyTab::Open } 
			::hwtk::toolbutton $frame2.save -image [hwtk::image cache fileSave-24.png] -help "Save" -command { ::hm::MyTab::Save } 
			::hwtk::toolbutton $frame2.saveas -image [hwtk::image cache fileSaveAs-24.png] -help "SaveAs" -command { ::hm::MyTab::SaveAs } 
			::hwtk::toolbutton $frame2.import -image [hwtk::image cache fileImport-24.png] -help "Import" -command { ::hm::MyTab::Import } 
			::hwtk::toolbutton $frame2.export -image [hwtk::image cache fileExport-24.png] -help "Export" -command { ::hm::MyTab::Export } 
			::hwtk::toolbutton $frame2.centroid -image [hwtk::image cache entityNodes-24.png] -help "Centroid" -command { ::hm::MyTab::ElementCentroid } 
			::hwtk::toolbutton $frame2.system -image [hwtk::image cache entitySystemsRectangular-24.png] -help "System" -command { hm_pushpanel systems } 
			grid $frame2.new $frame2.open $frame2.save $frame2.saveas $frame2.import $frame2.export $frame2.centroid $frame2.system 
			
		# Create the frame3
		set frame3 [labelframe $m_recess.frame3 -text "Sensor" ];
		pack $frame3 -side top -anchor nw -fill both -expand true;
			set m_split [panedwindow  $frame3.sf1 -orient vertical ]
			pack  $m_split -fill both -expand true
			set m_tree [::hwtk::treectrl $m_split.tree -showroot no ]
			set m_pa [ ::hwtk::pa::Area #auto $m_split.pa ] 
			$m_pa CloseEditorUponValueAccepted on
			$m_split add $m_split.tree -stretch always 
			$m_split add $m_split.pa -stretch never
        # Create the frame4
        set frame4 [frame $m_recess.frame4];
        pack $frame4 -side bottom -anchor nw -fill x;
			button $frame4.close -text "Close" -width $m_width -command ::hm::MyTab::Close 
			pack $frame4.close -side right
		
		::hm::MyTab::SetCallbacks;
		::hm::MyTab::SetTree;
    }
}

#################################################################
proc ::hm::MyTab::Close { args } {
	variable m_title;
	
	set ans [ Answer "Are you sure you want to leave?" okcancel ]
	if { $ans == "cancel" } { return }
	
	hm_framework removetab "$m_title";
	TearDownWindow after_deactivate;
}

proc ::hm::MyTab::Error { msg } {
	variable m_title;
	
	set ans [ Answer "Error : $msg" ok ]
	
	hm_framework removetab "$m_title";
	TearDownWindow after_deactivate;
}

#################################################################
proc ::hm::MyTab::SetTree { args } {
	variable m_tree;
	variable m_autofit 0;
	variable m_tree_root 0;
	variable m_gauge {};
	variable m_gauge_name {};
	variable m_sys_id {};
	variable m_Folder_name {};
	variable m_Folder_id {};
	variable m_current_Folder 0;
	
	$m_tree element create entityimage image
	$m_tree element create entityname str -editable 0
	$m_tree element create id uint -editable 0
	$m_tree element create systemid uint -editable 0
	$m_tree element create elemid uint -editable 0 
	$m_tree element create layer str -editable 0 
	$m_tree element create type str -editable 0 
	$m_tree element create export intcheck -editable 1 
	
	$m_tree column create entities -text Entity -elements {entityimage entityname} -expand 0
	$m_tree column create id -text ID -elements {id} -expand 0
	$m_tree column create sysid -text SysID -elements {systemid} -expand 0
	$m_tree column create eid -text EID -elements {elemid} -expand 0
	$m_tree column create layer -text Layer -elements {layer} -expand 0
	$m_tree column create type -text Type -elements {type} -expand 0
	$m_tree column create export -text Export -elements {export} -expand 0 -itemjustify right
	
	set m [hwtk::menu $m_tree.menu]
	$m item create -caption "Create" -command { ::hm::MyTab::Create } 
	$m item folder -parent create -caption "Folder" -command { ::hm::MyTab::CreateFolder } 
	$m item s_sensor -parent create -caption "Single" -command { ::hm::MyTab::CreateSensor "Single" } 
	$m item r_sensor -parent create -caption "Rosette" -command { ::hm::MyTab::CreateSensor "Rosette" } 
	$m item separator
	$m item edit -caption "Move to..." -command { ::hm::MyTab::MoveTo }
	$m item separator
	$m item delete -caption "Delete" -command { ::hm::MyTab::Delete }
	$m item separator
	$m item exportyes -caption "Set Export" -command { ::hm::MyTab::SetExport 1 }
	$m item exportyno -caption "Set Do Not Export" -command { ::hm::MyTab::SetExport 0 }
	$m item separator
	$m item autofit -caption "Auto Fit" -type checkbutton -variable [namespace current]::m_autofit
	
	$m_tree configure -menu $m
	$m_tree configure -showroot yes
	$m_tree configure -selectcommand { ::hm::MyTab::Update_PA }
	$m_tree item configure $m_tree_root -values [ list entityname "All Gauges (0)" ]
	
	bind $m_tree <Delete> { ::hm::MyTab::Delete }
	bind $m_tree <Key-q> { ::hm::MyTab::Review }
	bind $m_tree <Key-Q> { ::hm::MyTab::Review }
	
	HidePA 0
}

#################################################################
proc ::hm::MyTab::Review { } {
	variable m_InReview;
	
	if $m_InReview {
		ClearReview	
	} else {
	
		GetSelected
		
		if [DoReview ] {
			set m_InReview 1
		} 
	}
}

proc ::hm::MyTab::DoReview { } {
	variable m_tree;
	variable m_reviewrange;
	variable m_selected_sensor;
	variable m_autofit;
	
	if { [dict size $m_selected_sensor] ==0} { 
		ClearReview
		return 0
	}
	
	set systems [list]
	dict for { k v} $m_selected_sensor {
		lappend systems [ dict get [ $m_tree item cget $k -values] systemid ]
	}
	
	##
	set state [ hm_commandfilestate 0]
	hm_blockmessages 1
	##
	
	*clearmarkall 1
	eval *createmark systems 1 $systems
	*reviewentitybymark 1 0 1 0
	if { $m_autofit && [llength $systems]==1} {
		set xyz [hm_getvalue systems id=$systems dataname=origin]
		eval *graphuserwindow_byXYZandR $xyz $m_reviewrange
	}
	
	##
	hm_commandfilestate $state
	hm_blockmessages 0
	##
	return 1
}

proc ::hm::MyTab::ClearReview { } {
	variable m_InReview;
	##
	set state [ hm_commandfilestate 0]
	hm_blockmessages 1
	##
	*reviewclearall
	##
	hm_commandfilestate $state
	hm_blockmessages 0
	##
	set m_InReview 0
}

#################################################################
proc ::hm::MyTab::AddProperty { prop type label value {flag true} { parent "" } } {
	variable m_pa;
	$m_pa AddProperty $prop $type $parent
	$m_pa SetPropertyLabel $prop $label	
    $m_pa SetPropertyValue $prop $value
	$m_pa SetPropertyEnabled $prop $flag
}

proc ::hm::MyTab::GetSensorTypes { prop } {
	return [ list Single Rosette ]
}

proc ::hm::MyTab::SetSensorType { prop value } {
	variable m_selected_sensor;
	variable m_gauge;
	variable m_tree;
	
	dict for { k v } $m_selected_sensor {
		set si [ dict get [ $m_tree item cget $k -values] id ]
		dict set m_gauge $si type $value
		$m_tree item configure $k -values [list type $value ]
	}
	return 1
}

proc ::hm::MyTab::SetSensorID { prop value } {
	variable m_gauge;
	variable m_gauge_name;
	variable m_tree;
	variable m_selected_sensor;
	
	set i [ dict keys $m_selected_sensor]
	set si [ dict get [ $m_tree item cget $i -values] id ]
	
	dict set m_gauge_name [ dict get $m_gauge $si name] $value
	dict set m_gauge $value [ dict get $m_gauge $si ]
	dict unset m_gauge $si
	
	$m_tree item configure $i -values [list id $value ]
	
	return 1
}

proc ::hm::MyTab::SensorIDValidate { prop value } {
	variable m_gauge;
	
	if [ dict exists $m_gauge $value ] { return false }
}

proc ::hm::MyTab::SetSensorName { prop value } {
	variable m_gauge;
	variable m_gauge_name;
	variable m_selected_sensor;
	variable m_tree;
	
	set i [ dict keys $m_selected_sensor]
	set si [ dict get [ $m_tree item cget $i -values] id ]
	dict unset m_gauge_name [ dict get $m_gauge $si name]
	dict set m_gauge $si name $value
	dict set m_gauge_name $value $si
	$m_tree item configure $i -values [list entityname $value ]
	
	return 1
}

proc ::hm::MyTab::SensorNameValidate { prop value } {
	variable m_gauge_name;
	
	if [ dict exists $m_gauge_name $value ] { return false }
	
	if [ ValidateName $value ] {
		return true
	} else {
		return false
	}
}

proc ::hm::MyTab::SetFolderName { prop value } {
	variable m_Folder_id;
	variable m_Folder_name;
	variable m_selected_folder;
	
	set i [ dict keys $m_selected_folder]
	dict unset m_Folder_name [ dict get $m_Folder_id $i]
	dict set m_Folder_id $i $value
	dict set m_Folder_name $value $i
	Update_Folder $i
}

proc ::hm::MyTab::FolderNameValidate { prop value } {
	variable m_Folder_name;
	
	if [ dict exists $m_Folder_name $value ] { return false }
	
	if [ ValidateName $value ] {
		return true
	} else {
		return false
	}
}


#################################################################
proc ::hm::MyTab::Update_PA { } {
	variable m_selected_sensor;
	variable m_selected_folder;
	variable m_InReview;
	
	HidePA 0
	
	GetSelected_direct
	set n_f [ dict size $m_selected_folder]
	set n_s [ dict size $m_selected_sensor]
	
	if {$m_InReview} {
		DoReview 
	}
	
	if { $n_f == 0 && $n_s==1 } {
		ShowPA_SingleSensor
	} elseif {$n_f == 0 && $n_s>1} {
		ShowPA_MultiSensor
	} elseif {$n_f == 1 && $n_s==0} {
		ShowPA_Folder
	} else {
		ShowPA_None
	}
}

proc ::hm::MyTab::ShowPA_SingleSensor {  } {
	variable m_gauge;
	variable m_tree;
	variable m_selected_sensor;
	variable m_pa;
	variable m_layers;
	
	$m_pa Clear
	
	set i [ dict keys $m_selected_sensor]
	set si [ dict get [ $m_tree item cget $i -values] id ]
	set sysid [ dict get $m_gauge $si sysid ]
	
	AddProperty name str "Name"  [ dict get $m_gauge $si name ]
	$m_pa SetPropertyValueCallback name ::hm::MyTab::SetSensorName
	$m_pa SetPropertyValidateCallback name ::hm::MyTab::SensorNameValidate
	
	AddProperty id uint "ID"  $si
	$m_pa SetPropertyValueCallback id ::hm::MyTab::SetSensorID
	$m_pa SetPropertyValidateCallback id ::hm::MyTab::SensorIDValidate
	
	AddProperty type combobox "Type"  [ dict get $m_gauge $si type ] 
	$m_pa SetPropertyValueListCallback type ::hm::MyTab::GetSensorTypes
	$m_pa SetPropertyValueCallback type ::hm::MyTab::SetSensorType
	
	AddProperty system uin "System"  $sysid
	AddProperty xaxis str "xaxis" [ hm_getvalue systems id=$sysid dataname=xaxis ] false system
	AddProperty yaxis str "yaxis" [ hm_getvalue systems id=$sysid dataname=yaxis ] false system
	AddProperty zaxis str "zaxis" [ hm_getvalue systems id=$sysid dataname=zaxis ] false system
	
	AddProperty element uint "Element"  [ dict get $m_gauge $si eid ] false
	AddProperty layer str  "Layer"  [ dict get $m_gauge $si layer ] false
}

proc ::hm::MyTab::ShowPA_MultiSensor {  } {
	variable m_selected_sensor;
	variable m_pa;
	
	$m_pa Clear
	
	set i [ dict keys $m_selected_sensor]
	
	AddProperty name str "Name" "###" false
	AddProperty id uint "ID" "###" false
	
	AddProperty type combobox "Type"  "###"
	$m_pa SetPropertyValueListCallback type ::hm::MyTab::GetSensorTypes
	$m_pa SetPropertyValueCallback type ::hm::MyTab::SetSensorType
	
	AddProperty system uin "System"  "###" false	
	AddProperty element uint "Element"  "###" false
	AddProperty layer str  "Layer" "###" false	
}

##############
proc ::hm::MyTab::ShowPA_Folder {  } {
	variable m_tree;
	variable m_Folder_id;
	variable m_selected_folder;
	variable m_pa;
	
	$m_pa Clear
	
	set i [ dict keys $m_selected_folder]
	
	AddProperty name str "Name"  [ dict get $m_Folder_id $i ]
	$m_pa SetPropertyValueCallback name ::hm::MyTab::SetFolderName
	$m_pa SetPropertyValidateCallback name ::hm::MyTab::FolderNameValidate
}

proc ::hm::MyTab::ShowPA_None { } {
	variable m_pa;
	$m_pa Clear
}
#################################################################
proc ::hm::MyTab::GetSelected { } {
	variable m_tree;
	variable m_Folder_id;
	variable m_selected_sensor;
	variable m_selected_folder;
	
	set m_selected_sensor {}
	set m_selected_folder {}
	
	set sl [ $m_tree select ];
	
	foreach item $sl {
		if [ dict exists $m_Folder_id $item ] {
			dict incr m_selected_folder $item
			set childs [ $m_tree item children $item ]
			foreach child $childs {
				dict incr m_selected_sensor $child
			}
		} elseif { $item != 0} {
			dict incr m_selected_sensor $item
		}
	}
}
#################################################################
proc ::hm::MyTab::GetSelected_direct { } {
	variable m_tree;
	variable m_Folder_id;
	variable m_selected_sensor;
	variable m_selected_folder;
	
	set m_selected_sensor {}
	set m_selected_folder {}
	
	set sl [ $m_tree select ];
	
	foreach item $sl {
		if [ dict exists $m_Folder_id $item ] {
			dict incr m_selected_folder $item
		} elseif { $item != 0} {
			dict incr m_selected_sensor $item
		}
	}
}
#################################################################
proc ::hm::MyTab::SetExport { flag } {
	variable m_selected_sensor;
	variable m_tree;
	variable m_gauge;
	
	if { [ set sl [ $m_tree select ] ] == 0 } {
		dict for { k v } $m_gauge {
			$m_tree item configure [dict get $v trid] -values [list export $flag]
		}
	} else {	
		GetSelected		
		dict for { k v } $m_selected_sensor {
			$m_tree item configure $k -values [list export $flag]
		}
	}
}
#################################################################
proc ::hm::MyTab::Delete { } {
	variable m_selected_sensor;
	variable m_selected_folder;
	
	GetSelected
	
	if [ dict size $m_selected_folder] {
		set ans [ Answer "Are you sure you want to delete the selected Folder(s)? \n All children entities will be also deleted." okcancel ]
		if { $ans == "cancel" } { return }
	} elseif [ dict size $m_selected_sensor] {
		set ans [ Answer "Are you sure you want to delete the selected item(s)?" yesno ]
		if { $ans == "no" } { return }
	}
	
	DeleteSensor [ dict keys $m_selected_sensor]
	DeleteFolder [ dict keys $m_selected_folder]
	Deep_Update_Folder	
}
#################################################################
proc ::hm::MyTab::DeleteSensor { items } {
	variable m_tree;
	variable m_gauge;
	variable m_gauge_name;
	variable m_sys_id;
	
	foreach i $items {
		set si [ dict get [ $m_tree item cget $i -values] id ]
		dict unset m_sys_id [ dict get $m_gauge $si sysid ]
		dict unset m_gauge_name [ dict get $m_gauge $si name ]
		dict unset m_gauge $si
		$m_tree item delete $i
	}
}

proc ::hm::MyTab::DeleteFolder { items } {
	variable m_tree;
	variable m_Folder_id;
	variable m_Folder_name;
	
	foreach i $items {
		dict unset m_Folder_name [ dict get $m_Folder_id $i ]
		dict unset m_Folder_id $i
		$m_tree item delete $i
	}
}
#################################################################
proc ::hm::MyTab::MoveTo { } {
	variable m_tree;
	variable m_selected_sensor;
	variable m_Folder_name;
	
	GetSelected_direct
	
	set n_s [ dict size $m_selected_sensor]
	
	if { $n_s==0 } { return }
	
	set pname [hwtk::inputdialog -inputtype combobox \
								 -valuelistcommand "::hm::MyTab::ListFoldername" \
								 -x [winfo pointerx .] \
								 -y [winfo pointery .] ] 
	if [dict exists $m_Folder_name $pname] { 
		set p [ dict get $m_Folder_name $pname]
		dict for { k v } $m_selected_sensor {
			$m_tree item configure $k -parent $p
		}
	}
	
	Deep_Update_Folder
}

proc ::hm::MyTab::ListFoldername { } {
	variable m_Folder_name;
	return [dict keys $m_Folder_name]
}

#################################################################
proc ::hm::MyTab::HidePA { hide } {
	variable m_pa;
	variable m_split;
	
	$m_split paneconfigure $m_split.pa -hide $hide
}

#################################################################
proc ::hm::MyTab::CreateFolder { args } {
	set input [ string map { " " "" } [hwtk::inputdialog -text "Enter name:" -x [winfo pointerx .] -y [winfo pointery .] ] ]
	
	if [ regexp {[a-zA-Z]+[0-9a-zA-Z_-]*} $input name ] {
		return [ NewFolder $name ]
	} else {
		return 0
	}
}

#################################################################
proc ::hm::MyTab::CreateSensor { type } {
	
	##
	set state [ hm_commandfilestate 0]
	hm_blockmessages 1
	##
	*createmarkpanel systems 1 "select systems..."
	set allsystem [ hm_getmark systems 1 ]
	*clearmark systems 1
	
	set alelem [list]
	set parent [ GetParent ]
	
	foreach system_id $allsystem { 
		if [ set e_id [ AddSys $system_id $parent $type ] ] { lappend alelem $e_id } 
	}
	catch {
		eval *createmark elements 1 $alelem
		*numbersmark elements 1 1
	}
	
	Update_Folder $parent
	SetCurrentFolder $parent
	##
	hm_blockmessages 0
	hm_commandfilestate $state
	##
}

#################################################################
proc ::hm::MyTab::FindElem { system_id } {
	variable m_radius;
	
	if { $m_radius <= 0.0 } {
		set m_radius 10.0
	}
	set xyz [ hm_getvalue systems id=$system_id dataname=origin ]
	foreach { x y z } $xyz {break};
	set e_id [GetClosestElement $x $y $z $m_radius] 
	if { $e_id == 0 } {
		puts ">> No element was found within $m_radius units distance of the origin of system-$system_id <<"
		puts "   increace search radius and try again."
	}
	return $e_id
}

#################################################################
proc ::hm::MyTab::AddSys { system_id parent type  {name ""} } {
	variable m_sys_id;
	
	if [ dict exists $m_sys_id $system_id ] { return 0 }
	
	set e_id [FindElem $system_id] 
	if { $e_id == 0 } {	return 0 }
	
	set e_layer [ result_layer $e_id $system_id ]
	set id [GetNewSensorID]
	set name [ GetNewSensorName $id $name ]
	
	NewSensor $parent $name $id $system_id $e_id $e_layer $type 1
	
	return $e_id
}

proc ::hm::MyTab::NewSensor { parent name id system_id e_id e_layer type export } {
	variable m_tree;
	variable m_gauge;
	variable m_gauge_name;
	variable m_sys_id;
	
	set e_c [ hm_entityinfo centroid elements $e_id ]
	set sys_axis [ hm_getvalue systems id=$system_id dataname=axis ] 
	
	set tree_id [ $m_tree item create \
						-parent $parent \
						-values [ list entityimage entitySensors-16.png entityname $name id $id systemid $system_id elemid $e_id layer $e_layer type $type export $export ] ]
	
	dict set m_gauge $id [ dict create name $name sysid $system_id eid $e_id e_c $e_c axis $sys_axis layer $e_layer type $type trid $tree_id ]
	dict set m_gauge_name $name $id
	dict set m_sys_id $system_id $tree_id
}

proc ::hm::MyTab::GetNewSensorID { } {
	variable m_gauge
	return [ expr [ eval ::tcl::mathfunc::max 0 0 [dict keys $m_gauge] ] +1 ]
}

proc ::hm::MyTab::GetNewSensorName { id {name ""} } {
	variable m_gauge_name
	
	if { $name == "" } { set name "S${id}" }
	
	if [dict exists $m_gauge_name $name] {
		set fmt [ format "%s-\[1-9\]\*" $name]
		set names [ dict keys $m_gauge_name $fmt ]
		
		if { [ llength $names ] == 0 } {
			return "${name}-1"
		} else {
			set max 0
			foreach item $names {
				set i [lindex [ split $item "-" ] 1]
				if { $max < $i } { set max $i }
			}
			
			return "${name}-[expr $max+1]"
		}
	} else {
		return $name
	}
}

#################################################################
proc ::hm::MyTab::GetParent { args } {
	variable m_tree;
	variable m_current_Folder;
	variable m_Folder_id;
	
	if { $m_current_Folder == 0 } { NewFolder "Gauges"  }
	
	set sl [ $m_tree select ];
	set n [ llength $sl ]
	
	if { $n != 1 || $sl==0 } { return $m_current_Folder } 
	
	if [ dict exists $m_Folder_id $sl ] {return $sl	} 
	
	return [ $m_tree item parent $sl ]
}

#################################################################
proc ::hm::MyTab::NewFolder { name } {
	variable m_tree;
	variable m_Folder_name;
	variable m_Folder_id;
	
	
	if [ dict exists $m_Folder_name $name ] { return 0 }
	set tr_id [ $m_tree item create -values [ list entityimage folderSensors-16.png entityname "$name (0)" ] ]
	dict set m_Folder_name $name $tr_id
	dict set m_Folder_id $tr_id $name
	
	return [ SetCurrentFolder $tr_id]
}

proc ::hm::MyTab::SetCurrentFolder { id } {
	variable m_tree;
	variable m_Folder_id;
	variable m_current_Folder;
	
	if [ dict exists $m_Folder_id $id ] {
		$m_tree item configure $m_current_Folder -fontweight normal
		set m_current_Folder $id;
		$m_tree item configure $m_current_Folder -fontweight bold
	}
	return $m_current_Folder
}

proc ::hm::MyTab::Update_Folder { id } {
	variable m_tree;
	variable m_tree_root;
	variable m_Folder_id;
	variable m_gauge;
	
	if [ dict exists $m_Folder_id $id ] {
		set name [ dict get $m_Folder_id $id ]
	} else { 
		return
	}
	
	set num [ llength [ $m_tree item children $id ] ]
	set all [ dict size $m_gauge ]
	$m_tree item configure $m_tree_root -values [ list entityname "All Gauges ($all)" ]
	$m_tree item configure $id -values [ list entityname "$name ($num)" ]
}

proc ::hm::MyTab::Deep_Update_Folder { } {
	variable m_tree;
	variable m_tree_root;
	variable m_Folder_id;
	variable m_gauge;	
	variable m_current_Folder;
	
	set all [ dict size $m_gauge ]
	$m_tree item configure $m_tree_root -values [ list entityname "All Gauges ($all)" ]
	
	foreach item [ $m_tree item children $m_tree_root ] {
		set name [ dict get $m_Folder_id $item ]
		set num [ llength [ $m_tree item children $item ] ]
		$m_tree item configure $item -values [ list entityname "$name ($num)" ]
	}
	
	if [ dict exists $m_Folder_id $m_current_Folder ] { return }
	set all [ $m_tree item children $m_tree_root ]
	if { [llength $all] == 0 } { 
		set m_current_Folder 0
	} else {
		set m_current_Folder [ lindex $all 0]
	}
}

#################################################################
proc ::hm::MyTab::Export { } {	
	set types_r {
		{{gauge Files}      {.gauge}     }
		{{All Files}        *            }
	}
	set filename [ tk_getSaveFile -defaultextension "gauge" -initialdir " " -filetypes $types_r -title "Export File as ..."]
	if { $filename == "" } { return }
	if [ catch { open "$filename" w} res1 ] {
		puts "Cannot open $filename for write:$res1"
		return
	}
	
	DoExport $res1
	
	catch {close $res1}
	puts   "Export : $filename"
}

proc ::hm::MyTab::IsExport { id } {
	variable m_gauge;
	variable m_tree;
	
	set treeid [ dict get $m_gauge $id trid]
	set flag [ dict get [ $m_tree item cget $treeid -values] export ]
	if { $flag=="checkboxOn-16.png"} {
		return 1
	} else {
		return 0
	}
}

proc ::hm::MyTab::DoExport { outfile } {
	variable m_tree;
	variable m_gauge;
	
	dict for { k v } $m_gauge {
		if [ IsExport $k] {
			set name [ dict get $v name]
			set eid [dict get $v eid]
			set e_c [dict get $v e_c]
			set axis [ dict get $v axis]
			set layer [ dict get $v layer]
			set type [ dict get $v type]
			puts $outfile "$k $name $eid $e_c $axis $layer $type"
		}
	}
}

#################################################################
proc ::hm::MyTab::Import { } {	
	set types_r {
		{{gauge Files}      {.gauge}     }
		{{All Files}        *            }
	}
	set filename [ tk_getOpenFile -defaultextension "gauge" -initialdir " " -filetypes $types_r -title "Import File ..."]
	if { $filename == "" } { return 0}
	if [ catch { open "$filename" r} res1 ] {
		puts "Cannot open $filename for read:$res1"
		return 0
	}
	
	##
	set state [ hm_commandfilestate 0]
	hm_blockmessages 1
	##
	
	DoImport $res1
	
	##
	hm_blockmessages 0
	hm_commandfilestate $state
	##
	
	catch {close $res1}
	puts "Import : $filename"
	return 1
}

proc ::hm::MyTab::DoImport { infile } {
	variable m_tree;
	variable m_gauge;
	
	set parent [ GetParent ]
	
	while { [gets $infile line] >0} {
		set data [ split $line " " ]
		set name [ lindex $data 1]
		set e_c [ lrange $data 3 5]
		set xaxis [ lrange $data 6 8]
		set yaxis [ lrange $data 9 11]
		set type [ lindex $data 16]
		set sysid [ CreateSystem $e_c $xaxis $yaxis ]
		
		AddSys $sysid $parent $type $name
	}
	Update_Folder $parent
	SetCurrentFolder $parent
}

proc ::hm::MyTab::CreateSystem { e_c axisx axisy } {
	set n_c [ CreateNode $e_c]
	set n_x [ CreateNode [ AddVector $e_c [ScaleVector $axisx 10] ] ]
	set n_y [ CreateNode [ AddVector $e_c [ScaleVector $axisy 10] ] ]
	*createmark nodes 1 $n_c
	*systemcreate 1 0 $n_c x $n_x xy $n_y
	*createmark nodes 1 $n_c $n_x $n_y
	*nodemarkcleartempmark 1
	return [TheLast systems]
}

proc ::hm::MyTab::CreateNode { pos } {
	eval *createnode $pos 0 0 0
	return [TheLast nodes]
}

proc ::hm::MyTab::TheLast { type } {
	*createmark $type 1 -1
	set id [ hm_getmark $type 1]
	*clearmark $type 1
	return $id
}

#################################################################
proc ::hm::MyTab::Save { } {	
	variable m_file
	
	if { $m_file == "" } {
		return [SaveAs]
	} else {
		return [DoSave]
	}
}

proc ::hm::MyTab::SaveAs { } {	
	variable m_file
	
	set types_r {
		{{project Files}    {.project}   }
		{{All Files}        *            }
	}
	set filename [ tk_getSaveFile -defaultextension "project" -initialdir " " -filetypes $types_r -title "Save as ..."]
	if { $filename == "" } { return 0 }
	
	set m_file $filename
	return [DoSave]
}

proc ::hm::MyTab::DoSave { } {	
	variable m_file
	
	if [ catch { open "$m_file" w} res1 ] {
		puts "Cannot open $m_file for write:$res1"
		return 0
	}
	
	DoSaveWrite $res1
	
	catch {close $res1}
	puts   "Saved : $m_file"
	return 1
}

proc ::hm::MyTab::DoSaveWrite { outfile } {
	variable m_tree;
	variable m_Folder_id
	
	dict for { fid name } $m_Folder_id {
		puts $outfile "entityimage folderSensors-16.png entityname $name"
		foreach child [ $m_tree item children $fid] {
			puts $outfile "[$m_tree item cget $child -values]"
		}
	}
}
#################################################################
proc ::hm::MyTab::Open { } {
	variable m_file
	
	if [NotEmpty] {
		set ans [ Answer "Save what you have done?" yesnocancel ]
		switch -- $ans { 
			yes { Save }
			cancel {return 0}
		}
	}
	
	set types_r {
		{{project Files}    {.project}   }
		{{All Files}        *            }
	}
	set filename [ tk_getOpenFile -defaultextension "project" -initialdir " " -filetypes $types_r -title "Open ..."]
	if { $filename == "" } { return 0}
	
	set m_file $filename
	
	return [DoOpen]
}

proc ::hm::MyTab::NotEmpty { } {
	variable m_Folder_id
	return [dict size $m_Folder_id]
}

proc ::hm::MyTab::DoOpen { } {	
	variable m_file
	
	if [ catch { open "$m_file" r} res1 ] {
		puts "Cannot open $m_file for read:$res1"
		return 0
	}
	
	##
	set state [ hm_commandfilestate 0]
	hm_blockmessages 1
	##
	
	DoOpenRead $res1
	
	##
	hm_blockmessages 0
	hm_commandfilestate $state
	##
	
	catch {close $res1}
	puts   "Open : $m_file"
	return 1
}

proc ::hm::MyTab::DoOpenRead { infile } {
	
	Clear 
	set failed 0
	while { [gets $infile line] >0} {
		if { [dict size $line] < 4} {
			NewFolder [ dict get $line entityname]
		} else {
			set system_id [ dict get $line systemid]
			set e_id [ dict get $line elemid]
			set e_layer [ dict get $line layer]
			if [BasicCheck $system_id $e_id $e_layer] {
				set parent [ GetParent ]
				set name [ dict get $line entityname]
				set id [ dict get $line id]
				set type [ dict get $line type]
				set export [ string equal  [ dict get $line export]  "checkboxOn-16.png" ]
				
				NewSensor $parent $name $id $system_id $e_id $e_layer $type $export
			} else {
				incr failed
			}
		}
	}
	
	Deep_Update_Folder
	
	if $failed {
		Answer "There are $failed gauges failed to pass the basic check!\
				\nPlease make sure that this .project file is consistent with your model." ok 
	}
}


proc ::hm::MyTab::Clear { } {
	variable m_tree;
	variable m_tree_root;
	variable m_Folder_id;
	variable m_Folder_name;
	variable m_current_Folder;
	variable m_gauge;
	variable m_gauge_name;
	variable m_sys_id;
	
	set m_Folder_id {}
	set m_Folder_name {}
	set m_current_Folder 0
	set m_gauge {}
	set m_gauge_name {}
	set m_sys_id {}
	$m_tree item delete all
	$m_tree item configure $m_tree_root -values [ list entityname "All Gauges (0)" ]
}

proc ::hm::MyTab::BasicCheck { systemid eid layer } {
	if [ catch { string equal [result_layer $eid $systemid] $layer } ans ] {
		return 0
	} else {
		return $ans
	}
	
}
#################################################################
proc ::hm::MyTab::New { args } {
	variable m_file
	#~ puts $args
	if [NotEmpty] {
		set ans [ Answer "Save what you have done?" yesnocancel ]
		switch -- $ans { 
			yes { 
				if { ![Save] } {return 0}
			}
			cancel {return 0}
		}
	}
	
	Clear
	set m_file ""
	return 1
 }
#################################################################
proc ::hm::MyTab::RemoveSystem { args } {
	
	set data [  split $args "(,)" ]
	if { [lindex $data 1] == "systems" } {
		set sys [ hm_getmark systems [lindex $data 2] ]
		DeleteSensor [ getTreeID_by_sys $sys]
		Deep_Update_Folder
	} else {
		return 0
	}
}

proc ::hm::MyTab::getTreeID_by_sys { systems } {
	variable m_sys_id;
	
	set treeid [ list]
	foreach id $systems {
		if [ dict exists $m_sys_id $id] {
			lappend treeid [dict get $m_sys_id $id]
		}
	}
	return $treeid
}

#################################################################
if [ catch {::hm::MyTab::Main} err] {
	::hm::MyTab::Error $err
}
