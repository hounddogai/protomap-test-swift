@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledCareProtocolMappingTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newScheduledCareProtocolMapping("code-638", label: "label-509")
        #expect(item.status == Imaging.ScheduledCareProtocolMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Imaging.newScheduledCareProtocolMapping("code-638", label: "label-509")
        try item.moveTo(Imaging.ScheduledCareProtocolMappingStatus.stopped)
        #expect(item.status == Imaging.ScheduledCareProtocolMappingStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newScheduledCareProtocolMapping("code-638", label: "label-509")
        item.status = Imaging.ScheduledCareProtocolMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ScheduledCareProtocolMappingStatus.idle) }
    }
}
