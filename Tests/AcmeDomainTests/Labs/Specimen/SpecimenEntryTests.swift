@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenEntryTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSpecimenEntry("code-1", label: "label-929")
        #expect(item.status == Labs.SpecimenEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newSpecimenEntry("code-1", label: "label-929")
        try item.moveTo(Labs.SpecimenEntryStatus.active)
        #expect(item.status == Labs.SpecimenEntryStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSpecimenEntry("code-1", label: "label-929")
        item.status = Labs.SpecimenEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenEntryStatus.draft) }
    }
}
