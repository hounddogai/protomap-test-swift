@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessReviewTests {
    @Test func startsInNew() throws {
        let item = Consent.newWitnessReview("code-475", name: "name-907")
        #expect(item.status == Consent.WitnessReviewStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newWitnessReview("code-475", name: "name-907")
        try item.moveTo(Consent.WitnessReviewStatus.running)
        #expect(item.status == Consent.WitnessReviewStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newWitnessReview("code-475", name: "name-907")
        item.status = Consent.WitnessReviewStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.WitnessReviewStatus.new) }
    }
}
