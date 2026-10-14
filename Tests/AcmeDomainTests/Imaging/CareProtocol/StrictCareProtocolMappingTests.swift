@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStrictCareProtocolMappingTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newStrictCareProtocolMapping("code-564", title: "title-739")
        #expect(item.status == Imaging.StrictCareProtocolMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Imaging.newStrictCareProtocolMapping("code-564", title: "title-739")
        try item.moveTo(Imaging.StrictCareProtocolMappingStatus.warming)
        #expect(item.status == Imaging.StrictCareProtocolMappingStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newStrictCareProtocolMapping("code-564", title: "title-739")
        item.status = Imaging.StrictCareProtocolMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.StrictCareProtocolMappingStatus.idle) }
    }
}
