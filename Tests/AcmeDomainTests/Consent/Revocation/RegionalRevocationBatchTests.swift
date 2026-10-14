@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationBatchTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRegionalRevocationBatch("code-83", title: "title-325")
        #expect(item.status == Consent.RegionalRevocationBatchStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToValidated() throws {
        let item = Consent.newRegionalRevocationBatch("code-83", title: "title-325")
        try item.moveTo(Consent.RegionalRevocationBatchStatus.validated)
        #expect(item.status == Consent.RegionalRevocationBatchStatus.validated)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRegionalRevocationBatch("code-83", title: "title-325")
        item.status = Consent.RegionalRevocationBatchStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RegionalRevocationBatchStatus.created) }
    }
}
