@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureSegmentTests {
    @Test func startsInOpen() throws {
        let item = Consent.newBatchedDisclosureSegment("code-33", name: "name-549")
        #expect(item.status == Consent.BatchedDisclosureSegmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newBatchedDisclosureSegment("code-33", name: "name-549")
        try item.moveTo(Consent.BatchedDisclosureSegmentStatus.resolved)
        #expect(item.status == Consent.BatchedDisclosureSegmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newBatchedDisclosureSegment("code-33", name: "name-549")
        item.status = Consent.BatchedDisclosureSegmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedDisclosureSegmentStatus.`open`) }
    }
}
