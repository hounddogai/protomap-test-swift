@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentDigestTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newAssessmentDigest("code-757", label: "label-315")
        #expect(item.status == CareManagement.AssessmentDigestStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = CareManagement.newAssessmentDigest("code-757", label: "label-315")
        try item.moveTo(CareManagement.AssessmentDigestStatus.archived)
        #expect(item.status == CareManagement.AssessmentDigestStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newAssessmentDigest("code-757", label: "label-315")
        item.status = CareManagement.AssessmentDigestStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentDigestStatus.`open`) }
    }
}
