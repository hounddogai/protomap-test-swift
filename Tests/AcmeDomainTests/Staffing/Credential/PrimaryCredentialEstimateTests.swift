@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialEstimateTests {
    @Test func startsInDraft() throws {
        let item = Staffing.newPrimaryCredentialEstimate("code-607", title: "title-114")
        #expect(item.status == Staffing.PrimaryCredentialEstimateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = Staffing.newPrimaryCredentialEstimate("code-607", title: "title-114")
        try item.moveTo(Staffing.PrimaryCredentialEstimateStatus.closed)
        #expect(item.status == Staffing.PrimaryCredentialEstimateStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Staffing.newPrimaryCredentialEstimate("code-607", title: "title-114")
        item.status = Staffing.PrimaryCredentialEstimateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryCredentialEstimateStatus.draft) }
    }
}
