import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "order-set-window": { () -> Bool in
                    let store: any OrderSetWindowStore = newMemoryOrderSetWindowStore()
                    for index in 0..<5 {
                        store.save(newOrderSetWindow("order-set-window-\(index)", title: "Sample order set window \(index)"))
                    }
                    let flow = newOrderSetWindowDesk(store, clock: clock)
                    do {
                        try flow.advance("order-set-window-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildOrderSetWindowReport("Order Set Window", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.sweep(Int(Date().timeIntervalSince1970)) >= 0
                },
                "care-protocol-threshold": { () -> Bool in
                    let store: any CareProtocolThresholdStore = newMemoryCareProtocolThresholdStore()
                    for index in 0..<12 {
                        store.save(newCareProtocolThreshold("care-protocol-threshold-\(index)", title: "Sample care protocol threshold \(index)"))
                    }
                    let flow = newCareProtocolThresholdManager(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.openValue("care-protocol-threshold-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildCareProtocolThresholdReport("Care Protocol Threshold", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.reviewStale(Int(Date().timeIntervalSince1970)) >= 0
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
