@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyScheduleTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newStudySchedule("code-787", name: "name-62")
        #expect(item.status == Imaging.StudyScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newStudySchedule("code-787", name: "name-62")
        try item.moveTo(Imaging.StudyScheduleStatus.archived)
        #expect(item.status == Imaging.StudyScheduleStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newStudySchedule("code-787", name: "name-62")
        item.status = Imaging.StudyScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StudyScheduleStatus.`open`) }
    }
}
