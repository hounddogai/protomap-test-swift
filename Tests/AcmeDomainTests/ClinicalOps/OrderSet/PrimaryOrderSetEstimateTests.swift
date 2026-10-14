@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryOrderSetEstimateTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newPrimaryOrderSetEstimate("code-991", title: "title-473")
        #expect(item.status == ClinicalOps.PrimaryOrderSetEstimateStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newPrimaryOrderSetEstimate("code-991", title: "title-473")
        try item.moveTo(ClinicalOps.PrimaryOrderSetEstimateStatus.revoked)
        #expect(item.status == ClinicalOps.PrimaryOrderSetEstimateStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newPrimaryOrderSetEstimate("code-991", title: "title-473")
        item.status = ClinicalOps.PrimaryOrderSetEstimateStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.PrimaryOrderSetEstimateStatus.requested) }
    }
}
