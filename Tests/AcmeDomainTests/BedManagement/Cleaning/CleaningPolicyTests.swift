@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningPolicyTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newCleaningPolicy("code-208", label: "label-39")
        #expect(item.status == BedManagement.CleaningPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newCleaningPolicy("code-208", label: "label-39")
        try item.moveTo(BedManagement.CleaningPolicyStatus.rejected)
        #expect(item.status == BedManagement.CleaningPolicyStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newCleaningPolicy("code-208", label: "label-39")
        item.status = BedManagement.CleaningPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CleaningPolicyStatus.proposed) }
    }
}
