@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialCycleTests {
    @Test func startsInOpen() throws {
        let item = Staffing.newCredentialCycle("code-744", label: "label-844")
        #expect(item.status == Staffing.CredentialCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Staffing.newCredentialCycle("code-744", label: "label-844")
        try item.moveTo(Staffing.CredentialCycleStatus.inReview)
        #expect(item.status == Staffing.CredentialCycleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Staffing.newCredentialCycle("code-744", label: "label-844")
        item.status = Staffing.CredentialCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialCycleStatus.`open`) }
    }
}
