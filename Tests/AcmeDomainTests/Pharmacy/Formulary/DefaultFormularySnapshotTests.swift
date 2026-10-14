@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultFormularySnapshotTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDefaultFormularySnapshot("code-611", name: "name-681")
        #expect(item.status == Pharmacy.DefaultFormularySnapshotStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newDefaultFormularySnapshot("code-611", name: "name-681")
        try item.moveTo(Pharmacy.DefaultFormularySnapshotStatus.approved)
        #expect(item.status == Pharmacy.DefaultFormularySnapshotStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDefaultFormularySnapshot("code-611", name: "name-681")
        item.status = Pharmacy.DefaultFormularySnapshotStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultFormularySnapshotStatus.proposed) }
    }
}
