@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureRequestTests {
    @Test func startsInRequested() throws {
        let item = Consent.newBatchedDisclosureRequest("code-166", title: "title-322")
        #expect(item.status == Consent.BatchedDisclosureRequestStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newBatchedDisclosureRequest("code-166", title: "title-322")
        try item.moveTo(Consent.BatchedDisclosureRequestStatus.expired)
        #expect(item.status == Consent.BatchedDisclosureRequestStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newBatchedDisclosureRequest("code-166", title: "title-322")
        item.status = Consent.BatchedDisclosureRequestStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedDisclosureRequestStatus.requested) }
    }
}
