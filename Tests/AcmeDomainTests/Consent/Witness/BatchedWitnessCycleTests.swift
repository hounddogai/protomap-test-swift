@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessCycleTests {
    @Test func startsInNew() throws {
        let item = Consent.newBatchedWitnessCycle("code-121", name: "name-334")
        #expect(item.status == Consent.BatchedWitnessCycleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newBatchedWitnessCycle("code-121", name: "name-334")
        try item.moveTo(Consent.BatchedWitnessCycleStatus.queued)
        #expect(item.status == Consent.BatchedWitnessCycleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newBatchedWitnessCycle("code-121", name: "name-334")
        item.status = Consent.BatchedWitnessCycleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedWitnessCycleStatus.new) }
    }
}
