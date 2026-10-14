@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalSpecimenQuotaTests {
    @Test func startsInNew() throws {
        let item = Labs.newSeasonalSpecimenQuota("code-980", label: "label-498")
        #expect(item.status == Labs.SeasonalSpecimenQuotaStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newSeasonalSpecimenQuota("code-980", label: "label-498")
        try item.moveTo(Labs.SeasonalSpecimenQuotaStatus.queued)
        #expect(item.status == Labs.SeasonalSpecimenQuotaStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSeasonalSpecimenQuota("code-980", label: "label-498")
        item.status = Labs.SeasonalSpecimenQuotaStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalSpecimenQuotaStatus.new) }
    }
}
