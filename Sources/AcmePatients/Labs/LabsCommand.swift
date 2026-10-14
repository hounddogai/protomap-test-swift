import AcmePlatform
import Foundation

extension Labs {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "result-segment": { () -> Bool in
                    let store: any ResultSegmentStore = newMemoryResultSegmentStore()
                    for index in 0..<9 {
                        store.save(newResultSegment("result-segment-\(index)", label: "Sample result segment \(index)"))
                    }
                    let flow = newResultSegmentService(store, clock: clock)
                    do {
                        try flow.submit("result-segment-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildResultSegmentReport("Result Segment", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.sweep(Int(Date().timeIntervalSince1970)) >= 0
                },
                "reference-range-snapshot": { () -> Bool in
                    let store: any ReferenceRangeSnapshotStore = newMemoryReferenceRangeSnapshotStore()
                    for index in 0..<4 {
                        store.save(newReferenceRangeSnapshot("reference-range-snapshot-\(index)", title: "Sample reference range snapshot \(index)"))
                    }
                    let flow = newReferenceRangeSnapshotManager(store, clock: clock)
                    do {
                        try flow.submit("reference-range-snapshot-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildReferenceRangeSnapshotReport("Reference Range Snapshot", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.audit(Int(Date().timeIntervalSince1970)) >= 0
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
