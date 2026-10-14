@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultCareProtocolScheduleTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newDefaultCareProtocolSchedule("code-656", title: "title-605")
        #expect(item.status == Imaging.DefaultCareProtocolScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newDefaultCareProtocolSchedule("code-656", title: "title-605")
        try item.moveTo(Imaging.DefaultCareProtocolScheduleStatus.archived)
        #expect(item.status == Imaging.DefaultCareProtocolScheduleStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newDefaultCareProtocolSchedule("code-656", title: "title-605")
        item.status = Imaging.DefaultCareProtocolScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.DefaultCareProtocolScheduleStatus.`open`) }
    }
}
