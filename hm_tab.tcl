# HWVERSION_2017.1_Apr 12 2017_22:30:32
#################################################################
# File      : hm_tab.tcl
# Date      : June 7, 2007
# Created by: Altair Engineering, Inc.
# Purpose   : Creates a GUI to list all of the solver attributes
#             names, IDs, types and values for a particular
#             entity.
#################################################################

namespace eval ::hm::MyTab {
    variable m_title "MyTab";
	variable m_recess ".m_MyTab";
	variable m_rstfile "test.rst";
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
proc ::hm::MyTab::Main { args } {
    # Purpose:  Creates the GUI and calls the routine to populate
    #           the table.
    # Args:
    # Returns:
    # Notes:
	
    variable m_recess;
    variable m_rstfile;
	variable m_width 12;
    variable m_tree;
    variable m_pa;
	
    # Create the GUI
    if [::hm::MyTab::DialogCreate] {
        # Create the frame1
        set frame1 [frame $m_recess.frame1];
        pack $frame1 -side top -anchor nw -fill x ;

            # rst file
			set types_r {
				{{rst Files}       {.rst}        }
				{{All Files}        *            }
			}
			hwtk::label $frame1.l -text "rst file:"
			hwtk::openfileentry $frame1.e -textvariable [namespace current]::m_rstfile -filetypes $types_r -title "select result file" ;
			grid $frame1.l $frame1.e -sticky w -pady 2 -padx 5
			grid configure $frame1.e -sticky ew
			grid columnconfigure $frame1 1  -weight 1
		# Create the frame2
		set frame2 [frame $m_recess.frame2];
        pack $frame2 -side top -anchor nw -fill x ;
			button $frame2.open -text "Open" -width $m_width -command { puts "pressed - Open\n" } 
			button $frame2.save -text "Save" -width $m_width -command { puts "pressed - Save\n" } 
			button $frame2.export -text "Export" -width $m_width -command { puts "pressed - Export\n" } 
			pack $frame2.open $frame2.save $frame2.export -side left 
		# Create the frame3
		set frame3 [frame $m_recess.frame3];
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
			button $frame4.close -text "Close" -width $m_width -command { ::hm::MyTab::TearDownWindow "after_deactivate" } 
			pack $frame4.close -side right
		
		::hm::MyTab::SetCallbacks;
		::hm::MyTab::SetTree;
		::hm::MyTab::SetPa;
    }
}

#################################################################
proc ::hm::MyTab::SetTree { args } {
	variable m_tree;
}

#################################################################
proc ::hm::MyTab::SetPa { args } {
	variable m_pa;
}

#################################################################
::hm::MyTab::Main;
