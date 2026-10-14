import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "claim-segment": { () -> Bool in
                    let store: any ClaimSegmentStore = newMemoryClaimSegmentStore()
                    for index in 0..<12 {
                        store.save(newClaimSegment("claim-segment-\(index)", label: "Sample claim segment \(index)"))
                    }
                    let flow = newClaimSegmentDesk(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.advance("claim-segment-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildClaimSegmentReport("Claim Segment", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.sweep(Int(Date().timeIntervalSince1970)) >= 0
                },
                "remittance-adjustment": { () -> Bool in
                    let store: any RemittanceAdjustmentStore = newMemoryRemittanceAdjustmentStore()
                    for index in 0..<11 {
                        store.save(newRemittanceAdjustment("remittance-adjustment-\(index)", label: "Sample remittance adjustment \(index)"))
                    }
                    let flow = newRemittanceAdjustmentService(store, clock: clock)
                    do {
                        try flow.start("remittance-adjustment-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildRemittanceAdjustmentReport("Remittance Adjustment", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.scan(Int(Date().timeIntervalSince1970)) >= 0
                },
                "authorization-allocation": { () -> Bool in
                    let store: any AuthorizationAllocationStore = newMemoryAuthorizationAllocationStore()
                    for index in 0..<6 {
                        store.save(newAuthorizationAllocation("authorization-allocation-\(index)", name: "Sample authorization allocation \(index)"))
                    }
                    let flow = newAuthorizationAllocationWorkflow(store, clock: clock)
                    do {
                        try flow.openValue("authorization-allocation-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildAuthorizationAllocationReport("Authorization Allocation", items: items, clock: clock)
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
