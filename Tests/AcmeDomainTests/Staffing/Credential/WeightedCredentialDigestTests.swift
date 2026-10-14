@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingWeightedCredentialDigestTests {
    @Test func startsInCreated() throws {
        let item = Staffing.newWeightedCredentialDigest("code-595", label: "label-22")
        #expect(item.status == Staffing.WeightedCredentialDigestStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Staffing.newWeightedCredentialDigest("code-595", label: "label-22")
        try item.moveTo(Staffing.WeightedCredentialDigestStatus.validated)
        #expect(item.status == Staffing.WeightedCredentialDigestStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Staffing.newWeightedCredentialDigest("code-595", label: "label-22")
        item.status = Staffing.WeightedCredentialDigestStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Staffing.WeightedCredentialDigestStatus.created) }
    }
}
