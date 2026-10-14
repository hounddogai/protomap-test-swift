@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudyScheduleTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newBatchedStudySchedule("code-151", name: "name-961")
        #expect(item.status == Imaging.BatchedStudyScheduleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Imaging.newBatchedStudySchedule("code-151", name: "name-961")
        try item.moveTo(Imaging.BatchedStudyScheduleStatus.validated)
        #expect(item.status == Imaging.BatchedStudyScheduleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newBatchedStudySchedule("code-151", name: "name-961")
        item.status = Imaging.BatchedStudyScheduleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.BatchedStudyScheduleStatus.created) }
    }
}
