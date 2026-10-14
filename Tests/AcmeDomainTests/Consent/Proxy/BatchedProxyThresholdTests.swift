@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyThresholdTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newBatchedProxyThreshold("code-414", label: "label-266")
        #expect(item.status == Consent.BatchedProxyThresholdStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Consent.newBatchedProxyThreshold("code-414", label: "label-266")
        try item.moveTo(Consent.BatchedProxyThresholdStatus.completed)
        #expect(item.status == Consent.BatchedProxyThresholdStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newBatchedProxyThreshold("code-414", label: "label-266")
        item.status = Consent.BatchedProxyThresholdStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedProxyThresholdStatus.planned) }
    }
}
