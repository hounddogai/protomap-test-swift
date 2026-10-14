import AcmePlatform
import Foundation

extension Staffing {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "shift-allocation": { () -> Bool in
                    let store: any ShiftAllocationStore = newMemoryShiftAllocationStore()
                    for index in 0..<8 {
                        store.save(newShiftAllocation("shift-allocation-\(index)", title: "Sample shift allocation \(index)"))
                    }
                    let flow = newShiftAllocationCoordinator(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.start("shift-allocation-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildShiftAllocationReport("Shift Allocation", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.audit(Int(Date().timeIntervalSince1970)) >= 0
                },
                "float-pool-manifest": { () -> Bool in
                    let store: any FloatPoolManifestStore = newMemoryFloatPoolManifestStore()
                    for index in 0..<7 {
                        store.save(newFloatPoolManifest("float-pool-manifest-\(index)", label: "Sample float pool manifest \(index)"))
                    }
                    let flow = newFloatPoolManifestDesk(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.advance("float-pool-manifest-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildFloatPoolManifestReport("Float Pool Manifest", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.audit(Int(Date().timeIntervalSince1970)) >= 0
                },
                "overtime-snapshot": { () -> Bool in
                    let store: any OvertimeSnapshotStore = newMemoryOvertimeSnapshotStore()
                    for index in 0..<11 {
                        store.save(newOvertimeSnapshot("overtime-snapshot-\(index)", label: "Sample overtime snapshot \(index)"))
                    }
                    let flow = newOvertimeSnapshotWorkflow(store, clock: clock)
                    do {
                        try flow.openValue("overtime-snapshot-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildOvertimeSnapshotReport("Overtime Snapshot", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.scan(Int(Date().timeIntervalSince1970)) >= 0
                },
            ]
            var failed = 0
            for (name, command) in commands.sorted(by: { $0.key < $1.key }) {
                if !command() {
                    Swift.print("\(name) failed")
                    failed += 1
                }
            }
            if failed > 0 {
                Foundation.exit(Int32(1))
            }
        }
    }
}
