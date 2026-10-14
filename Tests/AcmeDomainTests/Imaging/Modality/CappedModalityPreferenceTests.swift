@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedModalityPreferenceTests {
    @Test func startsInIdle() throws {
        let item = Imaging.newCappedModalityPreference("code-619", title: "title-350")
        #expect(item.status == Imaging.CappedModalityPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Imaging.newCappedModalityPreference("code-619", title: "title-350")
        try item.moveTo(Imaging.CappedModalityPreferenceStatus.ready)
        #expect(item.status == Imaging.CappedModalityPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Imaging.newCappedModalityPreference("code-619", title: "title-350")
        item.status = Imaging.CappedModalityPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedModalityPreferenceStatus.idle) }
    }
}
