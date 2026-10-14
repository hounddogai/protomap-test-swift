@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInventoryDigestTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newLenientInventoryDigest("code-369", label: "label-490")
        #expect(item.status == Pharmacy.LenientInventoryDigestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newLenientInventoryDigest("code-369", label: "label-490")
        try item.moveTo(Pharmacy.LenientInventoryDigestStatus.suspended)
        #expect(item.status == Pharmacy.LenientInventoryDigestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newLenientInventoryDigest("code-369", label: "label-490")
        item.status = Pharmacy.LenientInventoryDigestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientInventoryDigestStatus.draft) }
    }
}
