@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenBundleTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSpecimenBundle("code-74", title: "title-1")
        #expect(item.status == Labs.SpecimenBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newSpecimenBundle("code-74", title: "title-1")
        try item.moveTo(Labs.SpecimenBundleStatus.pending)
        #expect(item.status == Labs.SpecimenBundleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSpecimenBundle("code-74", title: "title-1")
        item.status = Labs.SpecimenBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenBundleStatus.draft) }
    }
}
