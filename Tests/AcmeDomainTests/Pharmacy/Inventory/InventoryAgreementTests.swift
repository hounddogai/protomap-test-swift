@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryAgreementTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInventoryAgreement("code-167", title: "title-773")
        #expect(item.status == Pharmacy.InventoryAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Pharmacy.newInventoryAgreement("code-167", title: "title-773")
        try item.moveTo(Pharmacy.InventoryAgreementStatus.queued)
        #expect(item.status == Pharmacy.InventoryAgreementStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInventoryAgreement("code-167", title: "title-773")
        item.status = Pharmacy.InventoryAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InventoryAgreementStatus.new) }
    }
}
