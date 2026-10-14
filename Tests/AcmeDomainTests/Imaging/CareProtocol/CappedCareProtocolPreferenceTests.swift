@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedCareProtocolPreferenceTests {
    @Test func startsInCreated() throws {
        let item = Imaging.newCappedCareProtocolPreference("code-369", title: "title-271")
        #expect(item.status == Imaging.CappedCareProtocolPreferenceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Imaging.newCappedCareProtocolPreference("code-369", title: "title-271")
        try item.moveTo(Imaging.CappedCareProtocolPreferenceStatus.published)
        #expect(item.status == Imaging.CappedCareProtocolPreferenceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Imaging.newCappedCareProtocolPreference("code-369", title: "title-271")
        item.status = Imaging.CappedCareProtocolPreferenceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.CappedCareProtocolPreferenceStatus.created) }
    }
}
