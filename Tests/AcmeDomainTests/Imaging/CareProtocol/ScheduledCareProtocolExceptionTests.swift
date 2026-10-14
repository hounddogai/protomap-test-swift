@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolExceptionTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newScheduledCareProtocolException("code-784", title: "title-404")
        #expect(item.status == Imaging.ScheduledCareProtocolExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Imaging.newScheduledCareProtocolException("code-784", title: "title-404")
        try item.moveTo(Imaging.ScheduledCareProtocolExceptionStatus.archived)
        #expect(item.status == Imaging.ScheduledCareProtocolExceptionStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newScheduledCareProtocolException("code-784", title: "title-404")
        item.status = Imaging.ScheduledCareProtocolExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledCareProtocolExceptionStatus.`open`) }
    }
}
