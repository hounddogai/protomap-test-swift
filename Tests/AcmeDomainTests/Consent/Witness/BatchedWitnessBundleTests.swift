@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessBundleTests {
    @Test func startsInProposed() throws {
        let item = Consent.newBatchedWitnessBundle("code-349", name: "name-818")
        #expect(item.status == Consent.BatchedWitnessBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newBatchedWitnessBundle("code-349", name: "name-818")
        try item.moveTo(Consent.BatchedWitnessBundleStatus.rejected)
        #expect(item.status == Consent.BatchedWitnessBundleStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newBatchedWitnessBundle("code-349", name: "name-818")
        item.status = Consent.BatchedWitnessBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedWitnessBundleStatus.proposed) }
    }
}
