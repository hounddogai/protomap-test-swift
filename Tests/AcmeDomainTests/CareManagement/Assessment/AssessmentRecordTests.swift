@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentRecordTests {
    @Test func startsInIdle() throws {
        let item = CareManagement.newAssessmentRecord("code-754", title: "title-309")
        #expect(item.status == CareManagement.AssessmentRecordStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = CareManagement.newAssessmentRecord("code-754", title: "title-309")
        try item.moveTo(CareManagement.AssessmentRecordStatus.warming)
        #expect(item.status == CareManagement.AssessmentRecordStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = CareManagement.newAssessmentRecord("code-754", title: "title-309")
        item.status = CareManagement.AssessmentRecordStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentRecordStatus.idle) }
    }
}
