@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualFormularyReviewTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newManualFormularyReview("code-208", name: "name-99")
        #expect(item.status == Pharmacy.ManualFormularyReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newManualFormularyReview("code-208", name: "name-99")
        try item.moveTo(Pharmacy.ManualFormularyReviewStatus.running)
        #expect(item.status == Pharmacy.ManualFormularyReviewStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newManualFormularyReview("code-208", name: "name-99")
        item.status = Pharmacy.ManualFormularyReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.ManualFormularyReviewStatus.new) }
    }
}
