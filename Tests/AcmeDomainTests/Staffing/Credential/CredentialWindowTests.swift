@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialWindowTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCredentialWindow("code-33", label: "label-138")
        #expect(item.status == Staffing.CredentialWindowStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newCredentialWindow("code-33", label: "label-138")
        try item.moveTo(Staffing.CredentialWindowStatus.ready)
        #expect(item.status == Staffing.CredentialWindowStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCredentialWindow("code-33", label: "label-138")
        item.status = Staffing.CredentialWindowStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialWindowStatus.idle) }
    }
}
