@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialTierTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newRegionalCredentialTier("code-71", name: "name-894")
        #expect(item.status == Staffing.RegionalCredentialTierStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Staffing.newRegionalCredentialTier("code-71", name: "name-894")
        try item.moveTo(Staffing.RegionalCredentialTierStatus.revoked)
        #expect(item.status == Staffing.RegionalCredentialTierStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newRegionalCredentialTier("code-71", name: "name-894")
        item.status = Staffing.RegionalCredentialTierStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalCredentialTierStatus.requested) }
    }
}
