@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInventoryNoticeTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newAdaptiveInventoryNotice("code-584", title: "title-470")
        #expect(item.status == Pharmacy.AdaptiveInventoryNoticeStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newAdaptiveInventoryNotice("code-584", title: "title-470")
        try item.moveTo(Pharmacy.AdaptiveInventoryNoticeStatus.pending)
        #expect(item.status == Pharmacy.AdaptiveInventoryNoticeStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newAdaptiveInventoryNotice("code-584", title: "title-470")
        item.status = Pharmacy.AdaptiveInventoryNoticeStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveInventoryNoticeStatus.draft) }
    }
}
