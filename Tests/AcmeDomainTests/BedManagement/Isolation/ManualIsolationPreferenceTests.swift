@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementManualIsolationPreferenceTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newManualIsolationPreference("code-511", name: "name-949")
        #expect(item.status == BedManagement.ManualIsolationPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newManualIsolationPreference("code-511", name: "name-949")
        try item.moveTo(BedManagement.ManualIsolationPreferenceStatus.ready)
        #expect(item.status == BedManagement.ManualIsolationPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newManualIsolationPreference("code-511", name: "name-949")
        item.status = BedManagement.ManualIsolationPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ManualIsolationPreferenceStatus.idle) }
    }
}
