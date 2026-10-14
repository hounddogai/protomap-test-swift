@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialClaimTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newDenialClaim("code-623", label: "label-519")
        #expect(item.status == RevenueCycle.DenialClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newDenialClaim("code-623", label: "label-519")
        try item.moveTo(RevenueCycle.DenialClaimStatus.rejected)
        #expect(item.status == RevenueCycle.DenialClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newDenialClaim("code-623", label: "label-519")
        item.status = RevenueCycle.DenialClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialClaimStatus.proposed) }
    }
}
