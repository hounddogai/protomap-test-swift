@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLegacyCareGapVarianceTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newLegacyCareGapVariance("code-920", name: "name-461")
        #expect(item.status == CareManagement.LegacyCareGapVarianceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newLegacyCareGapVariance("code-920", name: "name-461")
        try item.moveTo(CareManagement.LegacyCareGapVarianceStatus.revoked)
        #expect(item.status == CareManagement.LegacyCareGapVarianceStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newLegacyCareGapVariance("code-920", name: "name-461")
        item.status = CareManagement.LegacyCareGapVarianceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.LegacyCareGapVarianceStatus.requested) }
    }
}
