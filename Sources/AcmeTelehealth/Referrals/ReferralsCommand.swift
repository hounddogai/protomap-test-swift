import AcmePlatform
import Foundation

extension Referrals {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "referral-budget": { () -> Bool in
                    let store: any ReferralBudgetStore = newMemoryReferralBudgetStore()
                    for index in 0..<4 {
                        store.save(newReferralBudget("referral-budget-\(index)", title: "Sample referral budget \(index)"))
                    }
                    let flow = newReferralBudgetWorkflow(store, clock: clock)
                    do {
                        try flow.advance("referral-budget-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildReferralBudgetReport("Referral Budget", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.reviewStale(Int(Date().timeIntervalSince1970)) >= 0
                },
                "network-policy": { () -> Bool in
                    let store: any NetworkPolicyStore = newMemoryNetworkPolicyStore()
                    for index in 0..<11 {
                        store.save(newNetworkPolicy("network-policy-\(index)", title: "Sample network policy \(index)"))
                    }
                    let flow = newNetworkPolicyWorkflow(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.start("network-policy-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildNetworkPolicyReport("Network Policy", items: items, clock: clock)
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
