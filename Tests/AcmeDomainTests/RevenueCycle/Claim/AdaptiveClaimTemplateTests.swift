@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimTemplateTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newAdaptiveClaimTemplate("code-537", name: "name-293")
        #expect(item.status == RevenueCycle.AdaptiveClaimTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newAdaptiveClaimTemplate("code-537", name: "name-293")
        try item.moveTo(RevenueCycle.AdaptiveClaimTemplateStatus.rejected)
        #expect(item.status == RevenueCycle.AdaptiveClaimTemplateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newAdaptiveClaimTemplate("code-537", name: "name-293")
        item.status = RevenueCycle.AdaptiveClaimTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AdaptiveClaimTemplateStatus.proposed) }
    }
}
