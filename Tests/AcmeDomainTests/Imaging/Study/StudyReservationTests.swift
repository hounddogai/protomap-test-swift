@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyReservationTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newStudyReservation("code-870", name: "name-4")
        #expect(item.status == Imaging.StudyReservationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Imaging.newStudyReservation("code-870", name: "name-4")
        try item.moveTo(Imaging.StudyReservationStatus.inReview)
        #expect(item.status == Imaging.StudyReservationStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newStudyReservation("code-870", name: "name-4")
        item.status = Imaging.StudyReservationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyReservationStatus.`open`) }
    }
}
