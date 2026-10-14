@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientRecallMilestoneTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newLenientRecallMilestone("code-920", label: "label-369")
        #expect(item.status == Pharmacy.LenientRecallMilestoneStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newLenientRecallMilestone("code-920", label: "label-369")
        try item.moveTo(Pharmacy.LenientRecallMilestoneStatus.resolved)
        #expect(item.status == Pharmacy.LenientRecallMilestoneStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newLenientRecallMilestone("code-920", label: "label-369")
        item.status = Pharmacy.LenientRecallMilestoneStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientRecallMilestoneStatus.`open`) }
    }
}
