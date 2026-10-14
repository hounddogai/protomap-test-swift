@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyReferenceRangeProfileTests {
    @Test func startsInOpen() throws {
        let item = Labs.newLegacyReferenceRangeProfile("code-626", label: "label-271")
        #expect(item.status == Labs.LegacyReferenceRangeProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newLegacyReferenceRangeProfile("code-626", label: "label-271")
        try item.moveTo(Labs.LegacyReferenceRangeProfileStatus.resolved)
        #expect(item.status == Labs.LegacyReferenceRangeProfileStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newLegacyReferenceRangeProfile("code-626", label: "label-271")
        item.status = Labs.LegacyReferenceRangeProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyReferenceRangeProfileStatus.`open`) }
    }
}
