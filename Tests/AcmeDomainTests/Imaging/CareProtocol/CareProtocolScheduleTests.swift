@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolScheduleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newCareProtocolSchedule("code-901", title: "title-305")
        #expect(item.status == Imaging.CareProtocolScheduleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newCareProtocolSchedule("code-901", title: "title-305")
        try item.moveTo(Imaging.CareProtocolScheduleStatus.failed)
        #expect(item.status == Imaging.CareProtocolScheduleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newCareProtocolSchedule("code-901", title: "title-305")
        item.status = Imaging.CareProtocolScheduleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolScheduleStatus.new) }
    }
}
