@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallEntryTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newRecallEntry("code-59", name: "name-889")
        #expect(item.status == Pharmacy.RecallEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newRecallEntry("code-59", name: "name-889")
        try item.moveTo(Pharmacy.RecallEntryStatus.done)
        #expect(item.status == Pharmacy.RecallEntryStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newRecallEntry("code-59", name: "name-889")
        item.status = Pharmacy.RecallEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallEntryStatus.new) }
    }
}
