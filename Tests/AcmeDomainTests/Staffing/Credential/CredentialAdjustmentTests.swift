@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newCredentialAdjustment("code-782", name: "name-942")
        #expect(item.status == Staffing.CredentialAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newCredentialAdjustment("code-782", name: "name-942")
        try item.moveTo(Staffing.CredentialAdjustmentStatus.completed)
        #expect(item.status == Staffing.CredentialAdjustmentStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newCredentialAdjustment("code-782", name: "name-942")
        item.status = Staffing.CredentialAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialAdjustmentStatus.planned) }
    }
}
