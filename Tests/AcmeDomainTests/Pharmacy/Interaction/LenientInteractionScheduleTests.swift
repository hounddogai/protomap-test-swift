@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientInteractionScheduleTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newLenientInteractionSchedule("code-388", title: "title-181")
        #expect(item.status == Pharmacy.LenientInteractionScheduleStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newLenientInteractionSchedule("code-388", title: "title-181")
        try item.moveTo(Pharmacy.LenientInteractionScheduleStatus.scheduled)
        #expect(item.status == Pharmacy.LenientInteractionScheduleStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newLenientInteractionSchedule("code-388", title: "title-181")
        item.status = Pharmacy.LenientInteractionScheduleStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientInteractionScheduleStatus.planned) }
    }
}
