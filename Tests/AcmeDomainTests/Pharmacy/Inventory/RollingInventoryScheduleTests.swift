@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingInventoryScheduleTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newRollingInventorySchedule("code-599", label: "label-808")
        #expect(item.status == Pharmacy.RollingInventoryScheduleStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToDraining() throws {
        let item = Pharmacy.newRollingInventorySchedule("code-599", label: "label-808")
        try item.moveTo(Pharmacy.RollingInventoryScheduleStatus.draining)
        #expect(item.status == Pharmacy.RollingInventoryScheduleStatus.draining)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newRollingInventorySchedule("code-599", label: "label-808")
        item.status = Pharmacy.RollingInventoryScheduleStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingInventoryScheduleStatus.idle) }
    }
}
