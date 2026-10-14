import AcmePlatform
import Foundation

extension Consent {
    /// Runs the area's jobs against sample data, as operators do from the command line.
    enum Command {
        static func run() {
            let clock: any Kit.Clocks.Clock = Kit.Clocks.system()
            let commands: [String: () -> Bool] = [
                "consent-form-adjustment": { () -> Bool in
                    let store: any ConsentFormAdjustmentStore = newMemoryConsentFormAdjustmentStore()
                    for index in 0..<10 {
                        store.save(newConsentFormAdjustment("consent-form-adjustment-\(index)", title: "Sample consent form adjustment \(index)"))
                    }
                    let flow = newConsentFormAdjustmentManager(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.submit("consent-form-adjustment-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildConsentFormAdjustmentReport("Consent Form Adjustment", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.scan(Int(Date().timeIntervalSince1970)) >= 0
                },
                "disclosure-threshold": { () -> Bool in
                    let store: any DisclosureThresholdStore = newMemoryDisclosureThresholdStore()
                    for index in 0..<9 {
                        store.save(newDisclosureThreshold("disclosure-threshold-\(index)", name: "Sample disclosure threshold \(index)"))
                    }
                    let flow = newDisclosureThresholdCoordinator(store, clock: clock)
                    do {
                        try flow.submit("disclosure-threshold-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildDisclosureThresholdReport("Disclosure Threshold", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.audit(Int(Date().timeIntervalSince1970)) >= 0
                },
                "proxy-proposal": { () -> Bool in
                    let store: any ProxyProposalStore = newMemoryProxyProposalStore()
                    for index in 0..<4 {
                        store.save(newProxyProposal("proxy-proposal-\(index)", name: "Sample proxy proposal \(index)"))
                    }
                    let flow = newProxyProposalManager(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.submit("proxy-proposal-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildProxyProposalReport("Proxy Proposal", items: items, clock: clock)
                    Swift.print(report.render())
                    return flow.audit(Int(Date().timeIntervalSince1970)) >= 0
                },
                "revocation-claim": { () -> Bool in
                    let store: any RevocationClaimStore = newMemoryRevocationClaimStore()
                    for index in 0..<12 {
                        store.save(newRevocationClaim("revocation-claim-\(index)", title: "Sample revocation claim \(index)"))
                    }
                    let flow = newRevocationClaimManager(store, clock: clock, flags: Kit.Flags.newRegistry())
                    do {
                        try flow.advance("revocation-claim-0")
                    } catch {
                        return false
                    }
                    let items = store.list()
                    let report = buildRevocationClaimReport("Revocation Claim", items: items, clock: clock)
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
