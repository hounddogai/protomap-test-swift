@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialClaimTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newDefaultCredentialClaim("code-199", title: "title-340")
        #expect(item.status == Staffing.DefaultCredentialClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = Staffing.newDefaultCredentialClaim("code-199", title: "title-340")
        try item.moveTo(Staffing.DefaultCredentialClaimStatus.pending)
        #expect(item.status == Staffing.DefaultCredentialClaimStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newDefaultCredentialClaim("code-199", title: "title-340")
        item.status = Staffing.DefaultCredentialClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultCredentialClaimStatus.draft) }
    }
}
