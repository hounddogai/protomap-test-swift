@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictAssessmentExceptionTests {
    @Test func startsInOpen() throws {
        let item = CareManagement.newStrictAssessmentException("code-179", label: "label-872")
        #expect(item.status == CareManagement.StrictAssessmentExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = CareManagement.newStrictAssessmentException("code-179", label: "label-872")
        try item.moveTo(CareManagement.StrictAssessmentExceptionStatus.resolved)
        #expect(item.status == CareManagement.StrictAssessmentExceptionStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = CareManagement.newStrictAssessmentException("code-179", label: "label-872")
        item.status = CareManagement.StrictAssessmentExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(CareManagement.StrictAssessmentExceptionStatus.`open`) }
    }
}
