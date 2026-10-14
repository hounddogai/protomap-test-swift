@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalCredentialTargetTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newSeasonalCredentialTarget("code-108", name: "name-465")
        #expect(item.status == Staffing.SeasonalCredentialTargetStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newSeasonalCredentialTarget("code-108", name: "name-465")
        try item.moveTo(Staffing.SeasonalCredentialTargetStatus.pending)
        #expect(item.status == Staffing.SeasonalCredentialTargetStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newSeasonalCredentialTarget("code-108", name: "name-465")
        item.status = Staffing.SeasonalCredentialTargetStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalCredentialTargetStatus.draft) }
    }
}
