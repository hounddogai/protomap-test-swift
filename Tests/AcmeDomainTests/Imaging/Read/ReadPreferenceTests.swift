@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingReadPreferenceTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newReadPreference("code-373", label: "label-872")
        #expect(item.status == Imaging.ReadPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Imaging.newReadPreference("code-373", label: "label-872")
        try item.moveTo(Imaging.ReadPreferenceStatus.granted)
        #expect(item.status == Imaging.ReadPreferenceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newReadPreference("code-373", label: "label-872")
        item.status = Imaging.ReadPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ReadPreferenceStatus.requested) }
    }
}
