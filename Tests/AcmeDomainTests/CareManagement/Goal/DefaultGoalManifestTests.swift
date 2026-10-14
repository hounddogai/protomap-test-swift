@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementDefaultGoalManifestTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newDefaultGoalManifest("code-40", label: "label-166")
        #expect(item.status == CareManagement.DefaultGoalManifestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = CareManagement.newDefaultGoalManifest("code-40", label: "label-166")
        try item.moveTo(CareManagement.DefaultGoalManifestStatus.inReview)
        #expect(item.status == CareManagement.DefaultGoalManifestStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newDefaultGoalManifest("code-40", label: "label-166")
        item.status = CareManagement.DefaultGoalManifestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.DefaultGoalManifestStatus.`open`) }
    }
}
