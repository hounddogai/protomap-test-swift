@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialTierTests {
    @Test func startsInNew() throws {
        let item = Staffing.newCredentialTier("code-350", name: "name-67")
        #expect(item.status == Staffing.CredentialTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newCredentialTier("code-350", name: "name-67")
        try item.moveTo(Staffing.CredentialTierStatus.queued)
        #expect(item.status == Staffing.CredentialTierStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newCredentialTier("code-350", name: "name-67")
        item.status = Staffing.CredentialTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialTierStatus.new) }
    }
}
