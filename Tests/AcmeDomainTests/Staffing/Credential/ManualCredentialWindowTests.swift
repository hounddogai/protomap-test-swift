@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualCredentialWindowTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newManualCredentialWindow("code-60", name: "name-156")
        #expect(item.status == Staffing.ManualCredentialWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Staffing.newManualCredentialWindow("code-60", name: "name-156")
        try item.moveTo(Staffing.ManualCredentialWindowStatus.rejected)
        #expect(item.status == Staffing.ManualCredentialWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newManualCredentialWindow("code-60", name: "name-156")
        item.status = Staffing.ManualCredentialWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.ManualCredentialWindowStatus.proposed) }
    }
}
