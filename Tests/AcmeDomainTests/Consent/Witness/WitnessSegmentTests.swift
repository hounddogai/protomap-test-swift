@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessSegmentTests {
    @Test func startsInDraft() throws {
        let item = Consent.newWitnessSegment("code-370", label: "label-289")
        #expect(item.status == Consent.WitnessSegmentStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Consent.newWitnessSegment("code-370", label: "label-289")
        try item.moveTo(Consent.WitnessSegmentStatus.pending)
        #expect(item.status == Consent.WitnessSegmentStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Consent.newWitnessSegment("code-370", label: "label-289")
        item.status = Consent.WitnessSegmentStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessSegmentStatus.draft) }
    }
}
