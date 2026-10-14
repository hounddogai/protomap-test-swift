@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultInteractionMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newDefaultInteractionMilestone("code-241", label: "label-749")
        #expect(item.status == Pharmacy.DefaultInteractionMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newDefaultInteractionMilestone("code-241", label: "label-749")
        try item.moveTo(Pharmacy.DefaultInteractionMilestoneStatus.resolved)
        #expect(item.status == Pharmacy.DefaultInteractionMilestoneStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newDefaultInteractionMilestone("code-241", label: "label-749")
        item.status = Pharmacy.DefaultInteractionMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultInteractionMilestoneStatus.`open`) }
    }
}
