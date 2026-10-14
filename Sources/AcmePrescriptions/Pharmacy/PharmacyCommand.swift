import AcmePlatform
import Foundation

extension Pharmacy {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "substitution-rollup": { () -> Bool in
                    let store: any SubstitutionRollupStore = newMemorySubstitutionRollupStore()
                    for index in 0..<8 {
                        store.save(newSubstitutionRollup("substitution-rollup-\(index)", name: "Sample substitution rollup \(index)"))
                    }
                    let flow = newSubstitutionRollupDesk(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.submit("substitution-rollup-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildSubstitutionRollupReport("Substitution Rollup", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.scan(Int(Date().timeIntervalSince1970)) >= 0
                },
                "inventory-score": { () -> Bool in
                    let store: any InventoryScoreStore = newMemoryInventoryScoreStore()
                    for index in 0..<10 {
                        store.save(newInventoryScore("inventory-score-\(index)", title: "Sample inventory score \(index)"))
                    }
                    let flow = newInventoryScoreWorkflow(store, clock: clock)
                    do {
                        try flow.openValue("inventory-score-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildInventoryScoreReport("Inventory Score", items: items, clock: clock)
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
