@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationPreferenceTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newIsolationPreference("code-891", label: "label-787")
        #expect(item.status == BedManagement.IsolationPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newIsolationPreference("code-891", label: "label-787")
        try item.moveTo(BedManagement.IsolationPreferenceStatus.ready)
        #expect(item.status == BedManagement.IsolationPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newIsolationPreference("code-891", label: "label-787")
        item.status = BedManagement.IsolationPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.IsolationPreferenceStatus.idle) }
    }
}
