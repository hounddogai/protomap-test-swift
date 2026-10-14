@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyScheduledFormularyMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newScheduledFormularyMilestone("code-529", title: "title-754")
        #expect(item.status == Pharmacy.ScheduledFormularyMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Pharmacy.newScheduledFormularyMilestone("code-529", title: "title-754")
        try item.moveTo(Pharmacy.ScheduledFormularyMilestoneStatus.completed)
        #expect(item.status == Pharmacy.ScheduledFormularyMilestoneStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newScheduledFormularyMilestone("code-529", title: "title-754")
        item.status = Pharmacy.ScheduledFormularyMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ScheduledFormularyMilestoneStatus.planned) }
    }
}
