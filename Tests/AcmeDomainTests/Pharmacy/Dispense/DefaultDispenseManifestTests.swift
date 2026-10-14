@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultDispenseManifestTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newDefaultDispenseManifest("code-815", title: "title-860")
        #expect(item.status == Pharmacy.DefaultDispenseManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newDefaultDispenseManifest("code-815", title: "title-860")
        try item.moveTo(Pharmacy.DefaultDispenseManifestStatus.approved)
        #expect(item.status == Pharmacy.DefaultDispenseManifestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newDefaultDispenseManifest("code-815", title: "title-860")
        item.status = Pharmacy.DefaultDispenseManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DefaultDispenseManifestStatus.proposed) }
    }
}
