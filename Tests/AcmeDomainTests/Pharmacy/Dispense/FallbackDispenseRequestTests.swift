@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseRequestTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newFallbackDispenseRequest("code-767", title: "title-979")
        #expect(item.status == Pharmacy.FallbackDispenseRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newFallbackDispenseRequest("code-767", title: "title-979")
        try item.moveTo(Pharmacy.FallbackDispenseRequestStatus.pending)
        #expect(item.status == Pharmacy.FallbackDispenseRequestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newFallbackDispenseRequest("code-767", title: "title-979")
        item.status = Pharmacy.FallbackDispenseRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackDispenseRequestStatus.draft) }
    }
}
