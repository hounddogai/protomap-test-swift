@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementScheduledCleaningThresholdTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newScheduledCleaningThreshold("code-276", name: "name-557")
        #expect(item.status == BedManagement.ScheduledCleaningThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newScheduledCleaningThreshold("code-276", name: "name-557")
        try item.moveTo(BedManagement.ScheduledCleaningThresholdStatus.warming)
        #expect(item.status == BedManagement.ScheduledCleaningThresholdStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newScheduledCleaningThreshold("code-276", name: "name-557")
        item.status = BedManagement.ScheduledCleaningThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.ScheduledCleaningThresholdStatus.idle) }
    }
}
