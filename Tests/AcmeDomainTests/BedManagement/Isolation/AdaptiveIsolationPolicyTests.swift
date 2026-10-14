@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveIsolationPolicyTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newAdaptiveIsolationPolicy("code-6", label: "label-45")
        #expect(item.status == BedManagement.AdaptiveIsolationPolicyStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = BedManagement.newAdaptiveIsolationPolicy("code-6", label: "label-45")
        try item.moveTo(BedManagement.AdaptiveIsolationPolicyStatus.done)
        #expect(item.status == BedManagement.AdaptiveIsolationPolicyStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newAdaptiveIsolationPolicy("code-6", label: "label-45")
        item.status = BedManagement.AdaptiveIsolationPolicyStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.AdaptiveIsolationPolicyStatus.new) }
    }
}
