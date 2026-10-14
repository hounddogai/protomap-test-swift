@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPolicyTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newIsolationPolicy("code-208", label: "label-735")
        #expect(item.status == BedManagement.IsolationPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newIsolationPolicy("code-208", label: "label-735")
        try item.moveTo(BedManagement.IsolationPolicyStatus.running)
        #expect(item.status == BedManagement.IsolationPolicyStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newIsolationPolicy("code-208", label: "label-735")
        item.status = BedManagement.IsolationPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationPolicyStatus.new) }
    }
}
