@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAssessmentMappingTests {
    @Test func startsInRequested() throws {
        let item = CareManagement.newAssessmentMapping("code-447", name: "name-906")
        #expect(item.status == CareManagement.AssessmentMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = CareManagement.newAssessmentMapping("code-447", name: "name-906")
        try item.moveTo(CareManagement.AssessmentMappingStatus.granted)
        #expect(item.status == CareManagement.AssessmentMappingStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = CareManagement.newAssessmentMapping("code-447", name: "name-906")
        item.status = CareManagement.AssessmentMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.AssessmentMappingStatus.requested) }
    }
}
