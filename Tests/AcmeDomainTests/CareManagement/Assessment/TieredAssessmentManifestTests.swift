@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredAssessmentManifestTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newTieredAssessmentManifest("code-272", title: "title-96")
        #expect(item.status == CareManagement.TieredAssessmentManifestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = CareManagement.newTieredAssessmentManifest("code-272", title: "title-96")
        try item.moveTo(CareManagement.TieredAssessmentManifestStatus.revoked)
        #expect(item.status == CareManagement.TieredAssessmentManifestStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newTieredAssessmentManifest("code-272", title: "title-96")
        item.status = CareManagement.TieredAssessmentManifestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.TieredAssessmentManifestStatus.requested) }
    }
}
