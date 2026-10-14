@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallDraftTests {
    @Test func startsInRequested() throws {
        let item = Pharmacy.newRecallDraft("code-68", title: "title-626")
        #expect(item.status == Pharmacy.RecallDraftStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Pharmacy.newRecallDraft("code-68", title: "title-626")
        try item.moveTo(Pharmacy.RecallDraftStatus.expired)
        #expect(item.status == Pharmacy.RecallDraftStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Pharmacy.newRecallDraft("code-68", title: "title-626")
        item.status = Pharmacy.RecallDraftStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallDraftStatus.requested) }
    }
}
