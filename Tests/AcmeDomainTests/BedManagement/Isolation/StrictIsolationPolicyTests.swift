@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementStrictIsolationPolicyTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newStrictIsolationPolicy("code-295", label: "label-7")
        #expect(item.status == BedManagement.StrictIsolationPolicyStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = BedManagement.newStrictIsolationPolicy("code-295", label: "label-7")
        try item.moveTo(BedManagement.StrictIsolationPolicyStatus.approved)
        #expect(item.status == BedManagement.StrictIsolationPolicyStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newStrictIsolationPolicy("code-295", label: "label-7")
        item.status = BedManagement.StrictIsolationPolicyStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.StrictIsolationPolicyStatus.proposed) }
    }
}
