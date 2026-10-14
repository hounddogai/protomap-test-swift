@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingLegacyCareProtocolPreferenceTests {
    @Test func startsInPlanned() throws {
        let item = Imaging.newLegacyCareProtocolPreference("code-589", title: "title-395")
        #expect(item.status == Imaging.LegacyCareProtocolPreferenceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Imaging.newLegacyCareProtocolPreference("code-589", title: "title-395")
        try item.moveTo(Imaging.LegacyCareProtocolPreferenceStatus.scheduled)
        #expect(item.status == Imaging.LegacyCareProtocolPreferenceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Imaging.newLegacyCareProtocolPreference("code-589", title: "title-395")
        item.status = Imaging.LegacyCareProtocolPreferenceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.LegacyCareProtocolPreferenceStatus.planned) }
    }
}
