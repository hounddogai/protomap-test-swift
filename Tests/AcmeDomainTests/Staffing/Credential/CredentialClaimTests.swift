@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialClaimTests {
    @Test func startsInNew() throws {
        let item = Staffing.newCredentialClaim("code-593", title: "title-701")
        #expect(item.status == Staffing.CredentialClaimStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Staffing.newCredentialClaim("code-593", title: "title-701")
        try item.moveTo(Staffing.CredentialClaimStatus.queued)
        #expect(item.status == Staffing.CredentialClaimStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newCredentialClaim("code-593", title: "title-701")
        item.status = Staffing.CredentialClaimStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialClaimStatus.new) }
    }
}
