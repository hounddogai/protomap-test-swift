@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolProfileTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newScheduledCareProtocolProfile("code-518", name: "name-222")
        #expect(item.status == Imaging.ScheduledCareProtocolProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Imaging.newScheduledCareProtocolProfile("code-518", name: "name-222")
        try item.moveTo(Imaging.ScheduledCareProtocolProfileStatus.reopened)
        #expect(item.status == Imaging.ScheduledCareProtocolProfileStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newScheduledCareProtocolProfile("code-518", name: "name-222")
        item.status = Imaging.ScheduledCareProtocolProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledCareProtocolProfileStatus.`open`) }
    }
}
