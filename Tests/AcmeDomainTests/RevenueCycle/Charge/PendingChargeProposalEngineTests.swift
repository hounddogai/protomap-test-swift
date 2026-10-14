@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingChargeProposalEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = RevenueCycle.defaultPendingChargeProposalEngine(Kit.Flags.newRegistry())
        let item = RevenueCycle.newPendingChargeProposal("code-758", title: "title-379")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
