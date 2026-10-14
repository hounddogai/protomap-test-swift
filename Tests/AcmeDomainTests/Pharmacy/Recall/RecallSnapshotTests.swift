@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallSnapshotTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRecallSnapshot("code-648", name: "name-473")
        #expect(item.status == Pharmacy.RecallSnapshotStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newRecallSnapshot("code-648", name: "name-473")
        try item.moveTo(Pharmacy.RecallSnapshotStatus.resolved)
        #expect(item.status == Pharmacy.RecallSnapshotStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRecallSnapshot("code-648", name: "name-473")
        item.status = Pharmacy.RecallSnapshotStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallSnapshotStatus.`open`) }
    }
}
