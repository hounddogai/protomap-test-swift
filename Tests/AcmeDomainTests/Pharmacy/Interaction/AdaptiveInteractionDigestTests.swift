@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionDigestTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newAdaptiveInteractionDigest("code-629", label: "label-67")
        #expect(item.status == Pharmacy.AdaptiveInteractionDigestStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newAdaptiveInteractionDigest("code-629", label: "label-67")
        try item.moveTo(Pharmacy.AdaptiveInteractionDigestStatus.inProgress)
        #expect(item.status == Pharmacy.AdaptiveInteractionDigestStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newAdaptiveInteractionDigest("code-629", label: "label-67")
        item.status = Pharmacy.AdaptiveInteractionDigestStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveInteractionDigestStatus.planned) }
    }
}
