@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialBatchTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newCredentialBatch("code-153", title: "title-152")
        #expect(item.status == Staffing.CredentialBatchStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Staffing.newCredentialBatch("code-153", title: "title-152")
        try item.moveTo(Staffing.CredentialBatchStatus.active)
        #expect(item.status == Staffing.CredentialBatchStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newCredentialBatch("code-153", title: "title-152")
        item.status = Staffing.CredentialBatchStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialBatchStatus.draft) }
    }
}
