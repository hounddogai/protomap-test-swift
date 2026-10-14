@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSummaryTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newCredentialSummary("code-342", name: "name-508")
        #expect(item.status == Staffing.CredentialSummaryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newCredentialSummary("code-342", name: "name-508")
        try item.moveTo(Staffing.CredentialSummaryStatus.validated)
        #expect(item.status == Staffing.CredentialSummaryStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newCredentialSummary("code-342", name: "name-508")
        item.status = Staffing.CredentialSummaryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialSummaryStatus.created) }
    }
}
