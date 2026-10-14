@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanPreferenceTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newDischargePlanPreference("code-660", name: "name-922")
        #expect(item.status == BedManagement.DischargePlanPreferenceStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = BedManagement.newDischargePlanPreference("code-660", name: "name-922")
        try item.moveTo(BedManagement.DischargePlanPreferenceStatus.ready)
        #expect(item.status == BedManagement.DischargePlanPreferenceStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newDischargePlanPreference("code-660", name: "name-922")
        item.status = BedManagement.DischargePlanPreferenceStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DischargePlanPreferenceStatus.idle) }
    }
}
