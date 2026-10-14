@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialExceptionTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCredentialException("code-790", title: "title-792")
        #expect(item.status == Staffing.CredentialExceptionStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newCredentialException("code-790", title: "title-792")
        try item.moveTo(Staffing.CredentialExceptionStatus.ready)
        #expect(item.status == Staffing.CredentialExceptionStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCredentialException("code-790", title: "title-792")
        item.status = Staffing.CredentialExceptionStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialExceptionStatus.idle) }
    }
}
