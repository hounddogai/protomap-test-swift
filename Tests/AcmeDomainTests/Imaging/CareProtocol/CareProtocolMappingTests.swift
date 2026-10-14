@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolMappingTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCareProtocolMapping("code-346", label: "label-166")
        #expect(item.status == Imaging.CareProtocolMappingStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newCareProtocolMapping("code-346", label: "label-166")
        try item.moveTo(Imaging.CareProtocolMappingStatus.granted)
        #expect(item.status == Imaging.CareProtocolMappingStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCareProtocolMapping("code-346", label: "label-166")
        item.status = Imaging.CareProtocolMappingStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolMappingStatus.requested) }
    }
}
