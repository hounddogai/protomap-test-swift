@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedSpecimenTierTests {
    @Test func startsInDraft() throws {
        let item = Labs.newCappedSpecimenTier("code-394", name: "name-744")
        #expect(item.status == Labs.CappedSpecimenTierStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Labs.newCappedSpecimenTier("code-394", name: "name-744")
        try item.moveTo(Labs.CappedSpecimenTierStatus.active)
        #expect(item.status == Labs.CappedSpecimenTierStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Labs.newCappedSpecimenTier("code-394", name: "name-744")
        item.status = Labs.CappedSpecimenTierStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedSpecimenTierStatus.draft) }
    }
}
