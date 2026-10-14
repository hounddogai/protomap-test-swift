@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInventoryScheduleTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newWeightedInventorySchedule("code-882", label: "label-183")
        #expect(item.status == Pharmacy.WeightedInventoryScheduleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = Pharmacy.newWeightedInventorySchedule("code-882", label: "label-183")
        try item.moveTo(Pharmacy.WeightedInventoryScheduleStatus.reopened)
        #expect(item.status == Pharmacy.WeightedInventoryScheduleStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newWeightedInventorySchedule("code-882", label: "label-183")
        item.status = Pharmacy.WeightedInventoryScheduleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.WeightedInventoryScheduleStatus.`open`) }
    }
}
