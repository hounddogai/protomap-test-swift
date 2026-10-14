@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionManifestTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newPrimarySubstitutionManifest("code-871", label: "label-572")
        #expect(item.status == Pharmacy.PrimarySubstitutionManifestStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = Pharmacy.newPrimarySubstitutionManifest("code-871", label: "label-572")
        try item.moveTo(Pharmacy.PrimarySubstitutionManifestStatus.suspended)
        #expect(item.status == Pharmacy.PrimarySubstitutionManifestStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newPrimarySubstitutionManifest("code-871", label: "label-572")
        item.status = Pharmacy.PrimarySubstitutionManifestStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimarySubstitutionManifestStatus.draft) }
    }
}
