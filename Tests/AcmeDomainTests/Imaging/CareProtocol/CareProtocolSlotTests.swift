@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolSlotTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCareProtocolSlot("code-875", title: "title-962")
        #expect(item.status == Imaging.CareProtocolSlotStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newCareProtocolSlot("code-875", title: "title-962")
        try item.moveTo(Imaging.CareProtocolSlotStatus.granted)
        #expect(item.status == Imaging.CareProtocolSlotStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCareProtocolSlot("code-875", title: "title-962")
        item.status = Imaging.CareProtocolSlotStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolSlotStatus.requested) }
    }
}
