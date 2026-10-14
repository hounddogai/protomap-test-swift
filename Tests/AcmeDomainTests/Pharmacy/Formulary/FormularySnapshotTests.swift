@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularySnapshotTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newFormularySnapshot("code-317", title: "title-528")
        #expect(item.status == Pharmacy.FormularySnapshotStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Pharmacy.newFormularySnapshot("code-317", title: "title-528")
        try item.moveTo(Pharmacy.FormularySnapshotStatus.published)
        #expect(item.status == Pharmacy.FormularySnapshotStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newFormularySnapshot("code-317", title: "title-528")
        item.status = Pharmacy.FormularySnapshotStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularySnapshotStatus.created) }
    }
}
