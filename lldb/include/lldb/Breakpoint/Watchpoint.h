//===-- Watchpoint.h --------------------------------------------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef liblldb_Watchpoint_h_
#define liblldb_Watchpoint_h_

// C Includes

// C++ Includes
#include <list>
#include <string>

// Other libraries and framework includes

// Project includes
#include "lldb/lldb-private.h"
#include "lldb/Target/Target.h"
#include "lldb/Core/UserID.h"
#include "lldb/Breakpoint/WatchpointOptions.h"
#include "lldb/Breakpoint/StoppointLocation.h"

namespace lldb_private {

class Watchpoint :
    public StoppointLocation
{
public:

    Watchpoint (lldb::addr_t addr, size_t size, bool hardware = true);

    ~Watchpoint ();

    void
    IncrementFalseAlarmsAndReviseHitCount();

    bool
    IsEnabled () const;

    void
    SetEnabled (bool enabled);

    virtual bool
    IsHardware () const;

    virtual bool
    ShouldStop (StoppointCallbackContext *context);

    bool        WatchpointRead () const;
    bool        WatchpointWrite () const;
    uint32_t    GetIgnoreCount () const;
    void        SetIgnoreCount (uint32_t n);
    void        SetWatchpointType (uint32_t type);
    void        SetDeclInfo (const std::string &str);
    std::string GetWatchSpec();
    void        SetWatchSpec (const std::string &str);

    // Snapshot management interface.
    bool        IsWatchVariable() const;
    void        SetWatchVariable(bool val);
    std::string GetOldSnapshot() const;
    void        SetOldSnapshot (const std::string &str);
    std::string GetNewSnapshot() const;
    void        SetNewSnapshot (const std::string &str);
    uint64_t    GetOldSnapshotVal() const;
    void        SetOldSnapshotVal (uint64_t val);
    uint64_t    GetNewSnapshotVal() const;
    void        SetNewSnapshotVal (uint64_t val);
    void        ClearSnapshots();

    void        GetDescription (Stream *s, lldb::DescriptionLevel level);
    void        Dump (Stream *s) const;
    void        DumpSnapshots (Stream *s, const char * prefix = NULL) const;
    void        DumpWithLevel (Stream *s, lldb::DescriptionLevel description_level) const;
    Target      &GetTarget() { return *m_target; }
    const Error &GetError() { return m_error; }

    //------------------------------------------------------------------
    /// Returns the WatchpointOptions structure set for this watchpoint.
    ///
    /// @return
    ///     A pointer to this watchpoint's WatchpointOptions.
    //------------------------------------------------------------------
    WatchpointOptions *
    GetOptions () { return &m_options; }

    //------------------------------------------------------------------
    /// Set the callback action invoked when the watchpoint is hit.  
    /// 
    /// @param[in] callback
    ///    The method that will get called when the watchpoint is hit.
    /// @param[in] callback_baton
    ///    A void * pointer that will get passed back to the callback function.
    /// @param[in] is_synchronous
    ///    If \b true the callback will be run on the private event thread
    ///    before the stop event gets reported.  If false, the callback will get
    ///    handled on the public event thead after the stop has been posted.
    ///
    /// @return
    ///    \b true if the process should stop when you hit the watchpoint.
    ///    \b false if it should continue.
    //------------------------------------------------------------------
    void
    SetCallback (WatchpointHitCallback callback, 
                 void *callback_baton,
                 bool is_synchronous = false);

    void
    SetCallback (WatchpointHitCallback callback, 
                 const lldb::BatonSP &callback_baton_sp,
                 bool is_synchronous = false);

    void        ClearCallback();

    //------------------------------------------------------------------
    /// Invoke the callback action when the watchpoint is hit.
    ///
    /// @param[in] context
    ///     Described the watchpoint event.
    ///
    /// @return
    ///     \b true if the target should stop at this watchpoint and \b false not.
    //------------------------------------------------------------------
    bool
    InvokeCallback (StoppointCallbackContext *context);

    //------------------------------------------------------------------
    // Condition
    //------------------------------------------------------------------
    //------------------------------------------------------------------
    /// Set the watchpoint's condition.
    ///
    /// @param[in] condition
    ///    The condition expression to evaluate when the watchpoint is hit.
    ///    Pass in NULL to clear the condition.
    //------------------------------------------------------------------
    void SetCondition (const char *condition);
    
    //------------------------------------------------------------------
    /// Return a pointer to the text of the condition expression.
    ///
    /// @return
    ///    A pointer to the condition expression text, or NULL if no
    //     condition has been set.
    //------------------------------------------------------------------
    const char *GetConditionText () const;

private:
    friend class Target;
    friend class WatchpointList;

    void        SetTarget(Target *target_ptr) { m_target = target_ptr; }
    void        ResetHitCount() { m_hit_count = 0; }

    Target      *m_target;
    bool        m_enabled;             // Is this watchpoint enabled
    bool        m_is_hardware;         // Is this a hardware watchpoint
    bool        m_is_watch_variable;   // True if set via 'watchpoint set variable'.
    uint32_t    m_watch_read:1,        // 1 if we stop when the watched data is read from
                m_watch_write:1,       // 1 if we stop when the watched data is written to
                m_watch_was_read:1,    // Set to 1 when watchpoint is hit for a read access
                m_watch_was_written:1; // Set to 1 when watchpoint is hit for a write access
    uint32_t    m_ignore_count;        // Number of times to ignore this watchpoint
    uint32_t    m_false_alarms;        // Number of false alarms.
    std::string m_decl_str;            // Declaration information, if any.
    std::string m_watch_spec_str;      // Spec for the watchpoint.
    std::string m_snapshot_old_str;    // Old snapshot for the watchpoint value as by ValueObject::DumpValueObject().
    std::string m_snapshot_new_str;    // New Snapshot for the watchpoint value as by ValueObject::DumpValueObject().
    uint64_t    m_snapshot_old_val;    // Old snapshot for the watchpoint bytes.
    uint64_t    m_snapshot_new_val;    // New Snapshot for the watchpoint bytes.
    Error       m_error;               // An error object describing errors associated with this watchpoint.
    WatchpointOptions m_options;       // Settable watchpoint options, which is a delegate to handle
                                       // the callback machinery.

    std::auto_ptr<ClangUserExpression> m_condition_ap;  // The condition to test.

    void SetID(lldb::watch_id_t id) { m_loc_id = id; }

    DISALLOW_COPY_AND_ASSIGN (Watchpoint);
};

} // namespace lldb_private

#endif  // liblldb_Watchpoint_h_
