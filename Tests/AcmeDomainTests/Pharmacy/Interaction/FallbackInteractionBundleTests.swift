@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInteractionBundleTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newFallbackInteractionBundle("code-141", title: "title-536")
        #expect(item.status == Pharmacy.FallbackInteractionBundleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Pharmacy.newFallbackInteractionBundle("code-141", title: "title-536")
        try item.moveTo(Pharmacy.FallbackInteractionBundleStatus.validated)
        #expect(item.status == Pharmacy.FallbackInteractionBundleStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newFallbackInteractionBundle("code-141", title: "title-536")
        item.status = Pharmacy.FallbackInteractionBundleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackInteractionBundleStatus.created) }
    }
}
