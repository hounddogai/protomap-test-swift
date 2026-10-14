@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingSeasonalCredentialTierTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newSeasonalCredentialTier("code-137", name: "name-316")
        #expect(item.status == Staffing.SeasonalCredentialTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newSeasonalCredentialTier("code-137", name: "name-316")
        try item.moveTo(Staffing.SeasonalCredentialTierStatus.revoked)
        #expect(item.status == Staffing.SeasonalCredentialTierStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newSeasonalCredentialTier("code-137", name: "name-316")
        item.status = Staffing.SeasonalCredentialTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.SeasonalCredentialTierStatus.requested) }
    }
}
