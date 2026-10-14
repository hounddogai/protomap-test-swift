@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionDraftTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newAdaptiveInteractionDraft("code-621", label: "label-64")
        #expect(item.status == Pharmacy.AdaptiveInteractionDraftStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newAdaptiveInteractionDraft("code-621", label: "label-64")
        try item.moveTo(Pharmacy.AdaptiveInteractionDraftStatus.running)
        #expect(item.status == Pharmacy.AdaptiveInteractionDraftStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newAdaptiveInteractionDraft("code-621", label: "label-64")
        item.status = Pharmacy.AdaptiveInteractionDraftStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.AdaptiveInteractionDraftStatus.new) }
    }
}
