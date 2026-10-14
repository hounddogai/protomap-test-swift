@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionNoticeTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newInteractionNotice("code-380", label: "label-352")
        #expect(item.status == Pharmacy.InteractionNoticeStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newInteractionNotice("code-380", label: "label-352")
        try item.moveTo(Pharmacy.InteractionNoticeStatus.withdrawn)
        #expect(item.status == Pharmacy.InteractionNoticeStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newInteractionNotice("code-380", label: "label-352")
        item.status = Pharmacy.InteractionNoticeStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionNoticeStatus.proposed) }
    }
}
