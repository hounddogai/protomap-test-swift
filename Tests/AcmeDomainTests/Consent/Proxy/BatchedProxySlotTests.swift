@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxySlotTests {
    @Test func startsInProposed() throws {
        let item = Consent.newBatchedProxySlot("code-657", label: "label-419")
        #expect(item.status == Consent.BatchedProxySlotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Consent.newBatchedProxySlot("code-657", label: "label-419")
        try item.moveTo(Consent.BatchedProxySlotStatus.withdrawn)
        #expect(item.status == Consent.BatchedProxySlotStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newBatchedProxySlot("code-657", label: "label-419")
        item.status = Consent.BatchedProxySlotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedProxySlotStatus.proposed) }
    }
}
