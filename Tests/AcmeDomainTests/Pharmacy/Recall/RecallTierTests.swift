@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallTierTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRecallTier("code-726", label: "label-445")
        #expect(item.status == Pharmacy.RecallTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Pharmacy.newRecallTier("code-726", label: "label-445")
        try item.moveTo(Pharmacy.RecallTierStatus.revoked)
        #expect(item.status == Pharmacy.RecallTierStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRecallTier("code-726", label: "label-445")
        item.status = Pharmacy.RecallTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallTierStatus.requested) }
    }
}
