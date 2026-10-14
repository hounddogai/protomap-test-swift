@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyCycleTests {
    @Test func startsInProposed() throws {
        let item = Consent.newBatchedProxyCycle("code-306", title: "title-473")
        #expect(item.status == Consent.BatchedProxyCycleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToWithdrawn() throws {
        let item = Consent.newBatchedProxyCycle("code-306", title: "title-473")
        try item.moveTo(Consent.BatchedProxyCycleStatus.withdrawn)
        #expect(item.status == Consent.BatchedProxyCycleStatus.withdrawn)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newBatchedProxyCycle("code-306", title: "title-473")
        item.status = Consent.BatchedProxyCycleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedProxyCycleStatus.proposed) }
    }
}
