@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialMetricTests {
    @Test func startsInPlanned() throws {
        let item = Staffing.newCredentialMetric("code-142", name: "name-464")
        #expect(item.status == Staffing.CredentialMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Staffing.newCredentialMetric("code-142", name: "name-464")
        try item.moveTo(Staffing.CredentialMetricStatus.completed)
        #expect(item.status == Staffing.CredentialMetricStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Staffing.newCredentialMetric("code-142", name: "name-464")
        item.status = Staffing.CredentialMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialMetricStatus.planned) }
    }
}
