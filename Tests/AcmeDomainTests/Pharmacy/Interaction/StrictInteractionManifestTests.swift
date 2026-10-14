@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictInteractionManifestTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newStrictInteractionManifest("code-389", label: "label-690")
        #expect(item.status == Pharmacy.StrictInteractionManifestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Pharmacy.newStrictInteractionManifest("code-389", label: "label-690")
        try item.moveTo(Pharmacy.StrictInteractionManifestStatus.scheduled)
        #expect(item.status == Pharmacy.StrictInteractionManifestStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newStrictInteractionManifest("code-389", label: "label-690")
        item.status = Pharmacy.StrictInteractionManifestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictInteractionManifestStatus.planned) }
    }
}
