@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedRecallNoticeTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newWeightedRecallNotice("code-341", label: "label-166")
        #expect(item.status == Pharmacy.WeightedRecallNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newWeightedRecallNotice("code-341", label: "label-166")
        try item.moveTo(Pharmacy.WeightedRecallNoticeStatus.active)
        #expect(item.status == Pharmacy.WeightedRecallNoticeStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newWeightedRecallNotice("code-341", label: "label-166")
        item.status = Pharmacy.WeightedRecallNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedRecallNoticeStatus.draft) }
    }
}
