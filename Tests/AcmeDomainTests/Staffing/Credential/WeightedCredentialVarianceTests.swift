@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialVarianceTests {
    @Test func startsInIdle() throws {
        let item = Staffing.newWeightedCredentialVariance("code-540", label: "label-33")
        #expect(item.status == Staffing.WeightedCredentialVarianceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Staffing.newWeightedCredentialVariance("code-540", label: "label-33")
        try item.moveTo(Staffing.WeightedCredentialVarianceStatus.stopped)
        #expect(item.status == Staffing.WeightedCredentialVarianceStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Staffing.newWeightedCredentialVariance("code-540", label: "label-33")
        item.status = Staffing.WeightedCredentialVarianceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedCredentialVarianceStatus.idle) }
    }
}
