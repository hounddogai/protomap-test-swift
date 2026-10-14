@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallMilestoneTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRecallMilestone("code-753", label: "label-507")
        #expect(item.status == Pharmacy.RecallMilestoneStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newRecallMilestone("code-753", label: "label-507")
        try item.moveTo(Pharmacy.RecallMilestoneStatus.inProgress)
        #expect(item.status == Pharmacy.RecallMilestoneStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRecallMilestone("code-753", label: "label-507")
        item.status = Pharmacy.RecallMilestoneStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallMilestoneStatus.planned) }
    }
}
