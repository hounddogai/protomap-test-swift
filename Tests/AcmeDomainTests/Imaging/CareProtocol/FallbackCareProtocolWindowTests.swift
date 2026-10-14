@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolWindowTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newFallbackCareProtocolWindow("code-739", title: "title-469")
        #expect(item.status == Imaging.FallbackCareProtocolWindowStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newFallbackCareProtocolWindow("code-739", title: "title-469")
        try item.moveTo(Imaging.FallbackCareProtocolWindowStatus.granted)
        #expect(item.status == Imaging.FallbackCareProtocolWindowStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newFallbackCareProtocolWindow("code-739", title: "title-469")
        item.status = Imaging.FallbackCareProtocolWindowStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.FallbackCareProtocolWindowStatus.requested) }
    }
}
