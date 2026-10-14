@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseEntryTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newDispenseEntry("code-719", title: "title-668")
        #expect(item.status == Pharmacy.DispenseEntryStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newDispenseEntry("code-719", title: "title-668")
        try item.moveTo(Pharmacy.DispenseEntryStatus.retired)
        #expect(item.status == Pharmacy.DispenseEntryStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newDispenseEntry("code-719", title: "title-668")
        item.status = Pharmacy.DispenseEntryStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseEntryStatus.created) }
    }
}
