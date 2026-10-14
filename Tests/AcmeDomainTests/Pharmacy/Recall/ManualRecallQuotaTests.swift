@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallQuotaTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newManualRecallQuota("code-839", label: "label-907")
        #expect(item.status == Pharmacy.ManualRecallQuotaStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newManualRecallQuota("code-839", label: "label-907")
        try item.moveTo(Pharmacy.ManualRecallQuotaStatus.reopened)
        #expect(item.status == Pharmacy.ManualRecallQuotaStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newManualRecallQuota("code-839", label: "label-907")
        item.status = Pharmacy.ManualRecallQuotaStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualRecallQuotaStatus.`open`) }
    }
}
