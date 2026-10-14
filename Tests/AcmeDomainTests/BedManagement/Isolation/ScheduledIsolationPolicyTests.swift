@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledIsolationPolicyTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newScheduledIsolationPolicy("code-960", name: "name-433")
        #expect(item.status == BedManagement.ScheduledIsolationPolicyStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newScheduledIsolationPolicy("code-960", name: "name-433")
        try item.moveTo(BedManagement.ScheduledIsolationPolicyStatus.ready)
        #expect(item.status == BedManagement.ScheduledIsolationPolicyStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newScheduledIsolationPolicy("code-960", name: "name-433")
        item.status = BedManagement.ScheduledIsolationPolicyStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledIsolationPolicyStatus.idle) }
    }
}
