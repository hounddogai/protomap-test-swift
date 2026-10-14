@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedChargeClaimTests {
    @Test func startsInRequested() throws {
        let item = RevenueCycle.newWeightedChargeClaim("code-434", name: "name-934")
        #expect(item.status == RevenueCycle.WeightedChargeClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = RevenueCycle.newWeightedChargeClaim("code-434", name: "name-934")
        try item.moveTo(RevenueCycle.WeightedChargeClaimStatus.granted)
        #expect(item.status == RevenueCycle.WeightedChargeClaimStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = RevenueCycle.newWeightedChargeClaim("code-434", name: "name-934")
        item.status = RevenueCycle.WeightedChargeClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.WeightedChargeClaimStatus.requested) }
    }
}
