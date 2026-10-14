@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallQuotaTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPendingRecallQuota("code-528", name: "name-93")
        #expect(item.status == Pharmacy.PendingRecallQuotaStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newPendingRecallQuota("code-528", name: "name-93")
        try item.moveTo(Pharmacy.PendingRecallQuotaStatus.validated)
        #expect(item.status == Pharmacy.PendingRecallQuotaStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPendingRecallQuota("code-528", name: "name-93")
        item.status = Pharmacy.PendingRecallQuotaStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallQuotaStatus.created) }
    }
}
