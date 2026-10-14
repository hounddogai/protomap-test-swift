@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadScheduleTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newReadSchedule("code-531", name: "name-72")
        #expect(item.status == Imaging.ReadScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Imaging.newReadSchedule("code-531", name: "name-72")
        try item.moveTo(Imaging.ReadScheduleStatus.completed)
        #expect(item.status == Imaging.ReadScheduleStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newReadSchedule("code-531", name: "name-72")
        item.status = Imaging.ReadScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadScheduleStatus.planned) }
    }
}
