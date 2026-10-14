@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialEstimateTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newCredentialEstimate("code-101", label: "label-174")
        #expect(item.status == Staffing.CredentialEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newCredentialEstimate("code-101", label: "label-174")
        try item.moveTo(Staffing.CredentialEstimateStatus.ready)
        #expect(item.status == Staffing.CredentialEstimateStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newCredentialEstimate("code-101", label: "label-174")
        item.status = Staffing.CredentialEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.CredentialEstimateStatus.idle) }
    }
}
