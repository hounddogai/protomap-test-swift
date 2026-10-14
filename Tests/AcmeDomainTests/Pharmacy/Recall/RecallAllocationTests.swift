@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallAllocationTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRecallAllocation("code-836", title: "title-831")
        #expect(item.status == Pharmacy.RecallAllocationStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newRecallAllocation("code-836", title: "title-831")
        try item.moveTo(Pharmacy.RecallAllocationStatus.resolved)
        #expect(item.status == Pharmacy.RecallAllocationStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRecallAllocation("code-836", title: "title-831")
        item.status = Pharmacy.RecallAllocationStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallAllocationStatus.`open`) }
    }
}
