# HWVERSION_2017.1_Apr 12 2017_22:30:32
#################################################################
# File      : hm_tab.tcl
# Date      : June 7, 2007
# Created by: Altair Engineering, Inc.
# Purpose   : Creates a GUI to list all of the solver attributes
#             names, IDs, types and values for a particular
#             entity.
#################################################################
catch {namespace delete ::hm::MyTab }

namespace eval ::hm::MyTab {
    variable m_title "MyTab";
	variable m_recess ".m_MyTab";
	variable m_rstfile "test.rst";
	variable m_radius 10;
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

    #~ ::hwt::AddCallback *templatefileset ::hm::MyTab::GetAttribs;
}

#################################################################
proc ::hm::MyTab::UnsetCallbacks { args } {
    # Purpose:  Undefines the callbacks when the tab is closed
    # Args:
    # Returns:
    # Notes:

    #~ ::hwt::RemoveCallback *templatefileset ::hm::MyTab::GetAttribs;
}

#################################################################
proc ::hm::MyTab::ElementCentroid { args } {
	*createmarkpanel elems 1 "Select Elements to create nodes at the centroid"
	set elemlist [hm_getmark elems 1]
	*clearmark elems 1
	set ellistlength [llength $elemlist]

	for {set i 0} {$i < $ellistlength} {incr i} {
		set elemid [lindex $elemlist $i]
		foreach {x y z} [hm_entityinfo centroid elems $elemid] {break};
		eval *createnode $x $y $z 0 0 0
		#~ *createmark nodes 1 -1
		#~ set newnode [hm_getmark nodes 1]
		#~ *clearmark nodes 1
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
		return -1
	} else {
		return 1
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
    variable m_rstfile;
	variable m_radius;
	variable m_width 12;
    variable m_tree;
    variable m_pa;
	
    # Create the GUI
    if [::hm::MyTab::DialogCreate] {
        # Create the frame1
        set frame1 [labelframe $m_recess.frame1 -text "Parameter" ];
        pack $frame1 -side top -anchor nw -fill x ;

            # rst file
			set types_r {
				{{rst Files}       {.rst}        }
				{{All Files}        *            }
			}
			hwtk::label $frame1.l1 -text "rst file:"
			hwtk::openfileentry $frame1.e1 -textvariable [namespace current]::m_rstfile -filetypes $types_r -title "select result file" ;
			grid $frame1.l1 $frame1.e1 -sticky w -pady 2 -padx 5
			grid configure $frame1.e1 -sticky ew
			
			hwtk::label $frame1.l2 -text "search radius:"
			hwtk::entry $frame1.e2 -inputtype double -textvariable [namespace current]::m_radius
			grid $frame1.l2 $frame1.e2 -sticky w -pady 2 -padx 5
			grid configure $frame1.e2 -sticky ew
			
			grid columnconfigure $frame1 1  -weight 1
			
		# Create the frame2
		set frame2 [labelframe $m_recess.frame2 -text "Command" ];
        pack $frame2 -side top -anchor nw -fill x ;
			button $frame2.open -text "Open" -width $m_width -command { puts "pressed - Open\n" } 
			button $frame2.save -text "Save" -width $m_width -command { puts "pressed - Save\n" } 
			button $frame2.import -text "Import" -width $m_width -command { puts "pressed - Import\n" } 
			button $frame2.export -text "Export" -width $m_width -command { puts "pressed - Export\n" } 
			button $frame2.centroid -text "Centroid" -width $m_width -command { ::hm::MyTab::ElementCentroid } 
			button $frame2.system -text "System" -width $m_width -command { hm_pushpanel systems } 
			grid $frame2.open $frame2.save 
			grid $frame2.import $frame2.export 
			grid $frame2.centroid $frame2.system 
			
		# Create the frame3
		set frame3 [labelframe $m_recess.frame3 -text "Sensor" ];
		pack $frame3 -side top -anchor nw -fill both -expand true;
			set sf1 [hwtk::splitframe $frame3.sf1 -orient vertical -help "Expand/Collapse" ]
			pack  $sf1 -fill both -expand true
			set m_tree [hwtk::treectrl $sf1.tree -showroot no ]
			set m_pa [ ::hwtk::pa::Area #auto $sf1.pa ] 
			$sf1 add $sf1.tree
			$sf1 add $sf1.pa
        # Create the frame4
        set frame4 [frame $m_recess.frame4];
        pack $frame4 -side bottom -anchor nw -fill x;
			button $frame4.close -text "Close" -width $m_width -command ::hm::MyTab::Close 
			pack $frame4.close -side right
		
		::hm::MyTab::SetCallbacks;
		::hm::MyTab::SetTree;
		::hm::MyTab::SetPa;
    }
}

#################################################################
proc ::hm::MyTab::Close { args } {
	variable m_title;
	
	hm_framework removetab "$m_title";
	TearDownWindow after_deactivate;
}

#################################################################
proc ::hm::MyTab::SetTree { args } {
	variable m_tree;
	variable m_gauge;
	variable m_max_id 0;
	set m_gauge {}
	
	$m_tree element create entityimage image
	$m_tree element create entityname str -editable 0
	$m_tree element create id uint -editable 0
	$m_tree element create systemid uint -editable 0
	$m_tree element create elemid uint -editable 0 
	$m_tree element create layer str -editable 0 
	
	$m_tree column create entities -text Entity -elements {entityimage entityname} -expand 0
	$m_tree column create id -text Id -elements {id} -expand 0
	$m_tree column create sysid -text SysId -elements {systemid} -expand 0
	$m_tree column create eid -text Eid -elements {elemid} -expand 0
	$m_tree column create layer -text Layer -elements {layer} -expand 0

	set m [hwtk::menu $m_tree.menu]
	$m item create -caption "Create" -command { ::hm::MyTab::Create } 
	#~ $m item folder -parent create -caption "Folder" -command { ::hm::MyTab::NewFolder } 
	#~ $m item sensor -parent create -caption "Sensor" -command { ::hm::MyTab::NewSensor } 
	$m item edit -caption "Edit" -command "puts Edit"
	$m item delete -caption "Delete" -command "puts Delete"
	
	$m_tree configure -menu $m
}

#################################################################
proc ::hm::MyTab::SetPa { args } {
	variable m_pa;
}

#################################################################
proc ::hm::MyTab::Create { args } {
	variable m_tree;
	variable m_radius;
	variable m_gauge;
	variable m_max_id;
	
	if { $m_radius <= 0.0 } {
		set m_radius 10.0
	}
	
	*createmarkpanel systems 1 "select systems..."
	set allsystem [ hm_getmark systems 1 ]
	
	set alelem [list]
	
	foreach system_id $allsystem { 
		puts "system -- $system_id"
		set xyz [ hm_getvalue systems id=$system_id dataname=origin ]
		foreach { x y z } $xyz {break};
		set e_id [GetClosestElement $x $y $z $m_radius] 
		if { $e_id == 0 } {
			puts ">> No element was found within $m_radius of the origin of system-$system_id <<"
			puts "   increace search radius and try again."
			continue 
        }
		set e_c [ hm_entityinfo centroid elements $e_id ]
		set sys_axis [ hm_getvalue systems id=$system_id dataname=axis ] 
		set e_layer [ result_layer $e_id $system_id ]
		lappend alelem $e_id
		incr m_max_id
		set tree_id [ NewSensor "S$m_max_id"  $m_max_id $system_id $e_id ]
		dict set m_gauge $m_max_id [ dict create name "S$m_max_id" sysid $system_id eid $e_id axis $sys_axis layer $e_layer trid $tree_id ]
		#~ puts "$system_id $e_id $e_c $sys_axis $e_layer"
	}
	catch {
	eval *createmark elements 1 $alelem
	*numbersmark elements 1 1}
}

#################################################################
proc ::hm::MyTab::NewSensor { name id sysid eid } {
	variable m_tree;	
	$m_tree item create -values [ list entityimage entitySensors-16.png entityname $name id $id systemid $sysid elemid $eid ]
}

proc ::hm::MyTab::NewFolder { args } {
	variable m_tree;
	$m_tree item create -values [ list entityimage folderSensors-16.png entityname F1 ]
}

#################################################################
::hm::MyTab::Main;
