@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newCareProtocolPreference("code-27", name: "name-976")
        #expect(item.status == Imaging.CareProtocolPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Imaging.newCareProtocolPreference("code-27", name: "name-976")
        try item.moveTo(Imaging.CareProtocolPreferenceStatus.cancelled)
        #expect(item.status == Imaging.CareProtocolPreferenceStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newCareProtocolPreference("code-27", name: "name-976")
        item.status = Imaging.CareProtocolPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CareProtocolPreferenceStatus.planned) }
    }
}
