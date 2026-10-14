@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalIsolationThresholdTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newSeasonalIsolationThreshold("code-638", label: "label-788")
        #expect(item.status == BedManagement.SeasonalIsolationThresholdStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = BedManagement.newSeasonalIsolationThreshold("code-638", label: "label-788")
        try item.moveTo(BedManagement.SeasonalIsolationThresholdStatus.active)
        #expect(item.status == BedManagement.SeasonalIsolationThresholdStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newSeasonalIsolationThreshold("code-638", label: "label-788")
        item.status = BedManagement.SeasonalIsolationThresholdStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.SeasonalIsolationThresholdStatus.draft) }
    }
}
