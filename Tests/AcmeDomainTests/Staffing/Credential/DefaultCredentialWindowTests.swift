@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialWindowTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newDefaultCredentialWindow("code-534", label: "label-989")
        #expect(item.status == Staffing.DefaultCredentialWindowStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newDefaultCredentialWindow("code-534", label: "label-989")
        try item.moveTo(Staffing.DefaultCredentialWindowStatus.validated)
        #expect(item.status == Staffing.DefaultCredentialWindowStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newDefaultCredentialWindow("code-534", label: "label-989")
        item.status = Staffing.DefaultCredentialWindowStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.DefaultCredentialWindowStatus.created) }
    }
}
