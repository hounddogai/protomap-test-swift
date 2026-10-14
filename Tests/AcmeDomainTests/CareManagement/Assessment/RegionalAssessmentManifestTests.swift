@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalAssessmentManifestTests {
    @Test func startsInPlanned() throws {
        let item = CareManagement.newRegionalAssessmentManifest("code-198", label: "label-605")
        #expect(item.status == CareManagement.RegionalAssessmentManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = CareManagement.newRegionalAssessmentManifest("code-198", label: "label-605")
        try item.moveTo(CareManagement.RegionalAssessmentManifestStatus.inProgress)
        #expect(item.status == CareManagement.RegionalAssessmentManifestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = CareManagement.newRegionalAssessmentManifest("code-198", label: "label-605")
        item.status = CareManagement.RegionalAssessmentManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.RegionalAssessmentManifestStatus.planned) }
    }
}
