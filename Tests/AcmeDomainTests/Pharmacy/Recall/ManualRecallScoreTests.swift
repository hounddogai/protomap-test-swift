@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallScoreTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newManualRecallScore("code-514", title: "title-225")
        #expect(item.status == Pharmacy.ManualRecallScoreStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newManualRecallScore("code-514", title: "title-225")
        try item.moveTo(Pharmacy.ManualRecallScoreStatus.pending)
        #expect(item.status == Pharmacy.ManualRecallScoreStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newManualRecallScore("code-514", title: "title-225")
        item.status = Pharmacy.ManualRecallScoreStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualRecallScoreStatus.draft) }
    }
}
