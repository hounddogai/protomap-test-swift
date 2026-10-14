@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentManifestTests {
    @Test func startsInDraft() throws {
        let item = CareManagement.newFallbackAssessmentManifest("code-368", title: "title-496")
        #expect(item.status == CareManagement.FallbackAssessmentManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = CareManagement.newFallbackAssessmentManifest("code-368", title: "title-496")
        try item.moveTo(CareManagement.FallbackAssessmentManifestStatus.active)
        #expect(item.status == CareManagement.FallbackAssessmentManifestStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = CareManagement.newFallbackAssessmentManifest("code-368", title: "title-496")
        item.status = CareManagement.FallbackAssessmentManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.FallbackAssessmentManifestStatus.draft) }
    }
}
