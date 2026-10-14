@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRollupTests {
    @Test func startsInNew() throws {
        let item = Staffing.newCredentialRollup("code-96", label: "label-438")
        #expect(item.status == Staffing.CredentialRollupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newCredentialRollup("code-96", label: "label-438")
        try item.moveTo(Staffing.CredentialRollupStatus.queued)
        #expect(item.status == Staffing.CredentialRollupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newCredentialRollup("code-96", label: "label-438")
        item.status = Staffing.CredentialRollupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialRollupStatus.new) }
    }
}
