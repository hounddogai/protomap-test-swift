@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialClaimTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newRegionalCredentialClaim("code-158", label: "label-566")
        #expect(item.status == Staffing.RegionalCredentialClaimStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Staffing.newRegionalCredentialClaim("code-158", label: "label-566")
        try item.moveTo(Staffing.RegionalCredentialClaimStatus.stopped)
        #expect(item.status == Staffing.RegionalCredentialClaimStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newRegionalCredentialClaim("code-158", label: "label-566")
        item.status = Staffing.RegionalCredentialClaimStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.RegionalCredentialClaimStatus.idle) }
    }
}
