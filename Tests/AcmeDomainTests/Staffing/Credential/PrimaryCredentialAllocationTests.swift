@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryCredentialAllocationTests {
    @Test func startsInRequested() throws {
        let item = Staffing.newPrimaryCredentialAllocation("code-324", title: "title-629")
        #expect(item.status == Staffing.PrimaryCredentialAllocationStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Staffing.newPrimaryCredentialAllocation("code-324", title: "title-629")
        try item.moveTo(Staffing.PrimaryCredentialAllocationStatus.granted)
        #expect(item.status == Staffing.PrimaryCredentialAllocationStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Staffing.newPrimaryCredentialAllocation("code-324", title: "title-629")
        item.status = Staffing.PrimaryCredentialAllocationStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.PrimaryCredentialAllocationStatus.requested) }
    }
}
