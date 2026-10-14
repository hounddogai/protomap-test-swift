@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseRequestTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDispenseRequest("code-860", name: "name-622")
        #expect(item.status == Pharmacy.DispenseRequestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Pharmacy.newDispenseRequest("code-860", name: "name-622")
        try item.moveTo(Pharmacy.DispenseRequestStatus.pending)
        #expect(item.status == Pharmacy.DispenseRequestStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDispenseRequest("code-860", name: "name-622")
        item.status = Pharmacy.DispenseRequestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseRequestStatus.draft) }
    }
}
