@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallQuotaTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRecallQuota("code-195", title: "title-54")
        #expect(item.status == Pharmacy.RecallQuotaStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newRecallQuota("code-195", title: "title-54")
        try item.moveTo(Pharmacy.RecallQuotaStatus.completed)
        #expect(item.status == Pharmacy.RecallQuotaStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRecallQuota("code-195", title: "title-54")
        item.status = Pharmacy.RecallQuotaStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallQuotaStatus.planned) }
    }
}
