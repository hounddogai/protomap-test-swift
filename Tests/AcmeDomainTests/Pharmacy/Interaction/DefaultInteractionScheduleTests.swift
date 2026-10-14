@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionScheduleTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDefaultInteractionSchedule("code-675", label: "label-433")
        #expect(item.status == Pharmacy.DefaultInteractionScheduleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Pharmacy.newDefaultInteractionSchedule("code-675", label: "label-433")
        try item.moveTo(Pharmacy.DefaultInteractionScheduleStatus.withdrawn)
        #expect(item.status == Pharmacy.DefaultInteractionScheduleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDefaultInteractionSchedule("code-675", label: "label-433")
        item.status = Pharmacy.DefaultInteractionScheduleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultInteractionScheduleStatus.proposed) }
    }
}
