@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialRollupTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newWeightedCredentialRollup("code-652", label: "label-354")
        #expect(item.status == Staffing.WeightedCredentialRollupStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Staffing.newWeightedCredentialRollup("code-652", label: "label-354")
        try item.moveTo(Staffing.WeightedCredentialRollupStatus.ready)
        #expect(item.status == Staffing.WeightedCredentialRollupStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newWeightedCredentialRollup("code-652", label: "label-354")
        item.status = Staffing.WeightedCredentialRollupStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedCredentialRollupStatus.idle) }
    }
}
