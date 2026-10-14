@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingWitnessReviewTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRollingWitnessReview("code-539", name: "name-746")
        #expect(item.status == Consent.RollingWitnessReviewStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = Consent.newRollingWitnessReview("code-539", name: "name-746")
        try item.moveTo(Consent.RollingWitnessReviewStatus.granted)
        #expect(item.status == Consent.RollingWitnessReviewStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRollingWitnessReview("code-539", name: "name-746")
        item.status = Consent.RollingWitnessReviewStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingWitnessReviewStatus.requested) }
    }
}
