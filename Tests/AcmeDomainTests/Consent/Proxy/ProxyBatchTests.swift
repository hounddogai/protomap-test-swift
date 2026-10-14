@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyBatchTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newProxyBatch("code-587", label: "label-626")
        #expect(item.status == Consent.ProxyBatchStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Consent.newProxyBatch("code-587", label: "label-626")
        try item.moveTo(Consent.ProxyBatchStatus.scheduled)
        #expect(item.status == Consent.ProxyBatchStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newProxyBatch("code-587", label: "label-626")
        item.status = Consent.ProxyBatchStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyBatchStatus.planned) }
    }
}
