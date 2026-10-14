import AcmePlatform
import Foundation

extension Imaging {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "study-metric": { () -> Bool in
                    let store: any StudyMetricStore = newMemoryStudyMetricStore()
                    for index in 0..<7 {
                        store.save(newStudyMetric("study-metric-\(index)", label: "Sample study metric \(index)"))
                    }
                    let flow = newStudyMetricService(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.openValue("study-metric-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildStudyMetricReport("Study Metric", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.sweep(Int(Date().timeIntervalSince1970)) >= 0
                },
                "worklist-estimate": { () -> Bool in
                    let store: any WorklistEstimateStore = newMemoryWorklistEstimateStore()
                    for index in 0..<8 {
                        store.save(newWorklistEstimate("worklist-estimate-\(index)", name: "Sample worklist estimate \(index)"))
                    }
                    let flow = newWorklistEstimateService(store, clock: clock)
                    do {
                        try flow.submit("worklist-estimate-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildWorklistEstimateReport("Worklist Estimate", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.sweep(Int(Date().timeIntervalSince1970)) >= 0
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
