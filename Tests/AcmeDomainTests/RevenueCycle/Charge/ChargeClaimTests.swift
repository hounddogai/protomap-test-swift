@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeClaimTests {
    @Test func startsInProposed() throws {
        let item = RevenueCycle.newChargeClaim("code-841", title: "title-345")
        #expect(item.status == RevenueCycle.ChargeClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = RevenueCycle.newChargeClaim("code-841", title: "title-345")
        try item.moveTo(RevenueCycle.ChargeClaimStatus.rejected)
        #expect(item.status == RevenueCycle.ChargeClaimStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = RevenueCycle.newChargeClaim("code-841", title: "title-345")
        item.status = RevenueCycle.ChargeClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ChargeClaimStatus.proposed) }
    }
}
