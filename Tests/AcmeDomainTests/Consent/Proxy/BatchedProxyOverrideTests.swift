@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyOverrideTests {
    @Test func startsInOpen() throws {
        let item = Consent.newBatchedProxyOverride("code-993", label: "label-67")
        #expect(item.status == Consent.BatchedProxyOverrideStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newBatchedProxyOverride("code-993", label: "label-67")
        try item.moveTo(Consent.BatchedProxyOverrideStatus.inReview)
        #expect(item.status == Consent.BatchedProxyOverrideStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newBatchedProxyOverride("code-993", label: "label-67")
        item.status = Consent.BatchedProxyOverrideStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedProxyOverrideStatus.`open`) }
    }
}
