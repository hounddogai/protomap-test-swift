@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAgreementTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newStudyAgreement("code-29", title: "title-4")
        #expect(item.status == Imaging.StudyAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newStudyAgreement("code-29", title: "title-4")
        try item.moveTo(Imaging.StudyAgreementStatus.completed)
        #expect(item.status == Imaging.StudyAgreementStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newStudyAgreement("code-29", title: "title-4")
        item.status = Imaging.StudyAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyAgreementStatus.planned) }
    }
}
