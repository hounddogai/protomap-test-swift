@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialRequestTests {
    @Test func startsInNew() throws {
        let item = Staffing.newPendingCredentialRequest("code-789", title: "title-547")
        #expect(item.status == Staffing.PendingCredentialRequestStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Staffing.newPendingCredentialRequest("code-789", title: "title-547")
        try item.moveTo(Staffing.PendingCredentialRequestStatus.running)
        #expect(item.status == Staffing.PendingCredentialRequestStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Staffing.newPendingCredentialRequest("code-789", title: "title-547")
        item.status = Staffing.PendingCredentialRequestStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PendingCredentialRequestStatus.new) }
    }
}
