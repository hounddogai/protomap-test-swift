@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledDenialClaimTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newScheduledDenialClaim("code-189", name: "name-66")
        #expect(item.status == RevenueCycle.ScheduledDenialClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = RevenueCycle.newScheduledDenialClaim("code-189", name: "name-66")
        try item.moveTo(RevenueCycle.ScheduledDenialClaimStatus.withdrawn)
        #expect(item.status == RevenueCycle.ScheduledDenialClaimStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newScheduledDenialClaim("code-189", name: "name-66")
        item.status = RevenueCycle.ScheduledDenialClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledDenialClaimStatus.proposed) }
    }
}
