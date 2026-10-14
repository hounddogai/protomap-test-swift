@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenPreferenceTests {
    @Test func startsInRequested() throws {
        let item = Labs.newSpecimenPreference("code-460", label: "label-23")
        #expect(item.status == Labs.SpecimenPreferenceStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Labs.newSpecimenPreference("code-460", label: "label-23")
        try item.moveTo(Labs.SpecimenPreferenceStatus.granted)
        #expect(item.status == Labs.SpecimenPreferenceStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Labs.newSpecimenPreference("code-460", label: "label-23")
        item.status = Labs.SpecimenPreferenceStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenPreferenceStatus.requested) }
    }
}
