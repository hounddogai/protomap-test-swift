@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolBaselineTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newCareProtocolBaseline("code-89", name: "name-921")
        #expect(item.status == Imaging.CareProtocolBaselineStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newCareProtocolBaseline("code-89", name: "name-921")
        try item.moveTo(Imaging.CareProtocolBaselineStatus.granted)
        #expect(item.status == Imaging.CareProtocolBaselineStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newCareProtocolBaseline("code-89", name: "name-921")
        item.status = Imaging.CareProtocolBaselineStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolBaselineStatus.requested) }
    }
}
