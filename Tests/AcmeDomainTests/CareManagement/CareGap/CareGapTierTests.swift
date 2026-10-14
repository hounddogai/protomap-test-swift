@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapTierTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newCareGapTier("code-459", label: "label-882")
        #expect(item.status == CareManagement.CareGapTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newCareGapTier("code-459", label: "label-882")
        try item.moveTo(CareManagement.CareGapTierStatus.revoked)
        #expect(item.status == CareManagement.CareGapTierStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newCareGapTier("code-459", label: "label-882")
        item.status = CareManagement.CareGapTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.CareGapTierStatus.requested) }
    }
}
