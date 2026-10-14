@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictSpecimenEntryTests {
    @Test func startsInDraft() throws {
        let item = Labs.newStrictSpecimenEntry("code-190", name: "name-725")
        #expect(item.status == Labs.StrictSpecimenEntryStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Labs.newStrictSpecimenEntry("code-190", name: "name-725")
        try item.moveTo(Labs.StrictSpecimenEntryStatus.closed)
        #expect(item.status == Labs.StrictSpecimenEntryStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newStrictSpecimenEntry("code-190", name: "name-725")
        item.status = Labs.StrictSpecimenEntryStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.StrictSpecimenEntryStatus.draft) }
    }
}
