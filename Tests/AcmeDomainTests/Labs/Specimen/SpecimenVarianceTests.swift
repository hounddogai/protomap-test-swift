@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenVarianceTests {
    @Test func startsInDraft() throws {
        let item = Labs.newSpecimenVariance("code-668", title: "title-473")
        #expect(item.status == Labs.SpecimenVarianceStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Labs.newSpecimenVariance("code-668", title: "title-473")
        try item.moveTo(Labs.SpecimenVarianceStatus.pending)
        #expect(item.status == Labs.SpecimenVarianceStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newSpecimenVariance("code-668", title: "title-473")
        item.status = Labs.SpecimenVarianceStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SpecimenVarianceStatus.draft) }
    }
}
