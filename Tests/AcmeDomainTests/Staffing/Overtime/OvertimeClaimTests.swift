@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeClaimTests {
    @Test func startsInProposed() throws {
        let item = Staffing.newOvertimeClaim("code-607", label: "label-69")
        #expect(item.status == Staffing.OvertimeClaimStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Staffing.newOvertimeClaim("code-607", label: "label-69")
        try item.moveTo(Staffing.OvertimeClaimStatus.approved)
        #expect(item.status == Staffing.OvertimeClaimStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Staffing.newOvertimeClaim("code-607", label: "label-69")
        item.status = Staffing.OvertimeClaimStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.OvertimeClaimStatus.proposed) }
    }
}
