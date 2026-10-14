@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenDraftTests {
    @Test func startsInNew() throws {
        let item = Labs.newSpecimenDraft("code-253", name: "name-32")
        #expect(item.status == Labs.SpecimenDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Labs.newSpecimenDraft("code-253", name: "name-32")
        try item.moveTo(Labs.SpecimenDraftStatus.failed)
        #expect(item.status == Labs.SpecimenDraftStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSpecimenDraft("code-253", name: "name-32")
        item.status = Labs.SpecimenDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenDraftStatus.new) }
    }
}
