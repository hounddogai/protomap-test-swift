@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSegmentTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newCredentialSegment("code-658", label: "label-882")
        #expect(item.status == Staffing.CredentialSegmentStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newCredentialSegment("code-658", label: "label-882")
        try item.moveTo(Staffing.CredentialSegmentStatus.approved)
        #expect(item.status == Staffing.CredentialSegmentStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newCredentialSegment("code-658", label: "label-882")
        item.status = Staffing.CredentialSegmentStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialSegmentStatus.proposed) }
    }
}
