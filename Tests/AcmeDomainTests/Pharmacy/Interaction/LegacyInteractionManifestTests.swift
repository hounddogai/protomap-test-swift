@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionManifestTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newLegacyInteractionManifest("code-839", label: "label-183")
        #expect(item.status == Pharmacy.LegacyInteractionManifestStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newLegacyInteractionManifest("code-839", label: "label-183")
        try item.moveTo(Pharmacy.LegacyInteractionManifestStatus.approved)
        #expect(item.status == Pharmacy.LegacyInteractionManifestStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newLegacyInteractionManifest("code-839", label: "label-183")
        item.status = Pharmacy.LegacyInteractionManifestStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LegacyInteractionManifestStatus.proposed) }
    }
}
