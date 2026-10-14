@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangePolicyTests {
    @Test func startsInOpen() throws {
        let item = Labs.newReferenceRangePolicy("code-660", label: "label-168")
        #expect(item.status == Labs.ReferenceRangePolicyStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Labs.newReferenceRangePolicy("code-660", label: "label-168")
        try item.moveTo(Labs.ReferenceRangePolicyStatus.resolved)
        #expect(item.status == Labs.ReferenceRangePolicyStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newReferenceRangePolicy("code-660", label: "label-168")
        item.status = Labs.ReferenceRangePolicyStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangePolicyStatus.`open`) }
    }
}
