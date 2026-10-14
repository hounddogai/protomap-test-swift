@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAgreementTests {
    @Test func startsInNew() throws {
        let item = Labs.newReferenceRangeAgreement("code-738", title: "title-521")
        #expect(item.status == Labs.ReferenceRangeAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Labs.newReferenceRangeAgreement("code-738", title: "title-521")
        try item.moveTo(Labs.ReferenceRangeAgreementStatus.queued)
        #expect(item.status == Labs.ReferenceRangeAgreementStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newReferenceRangeAgreement("code-738", title: "title-521")
        item.status = Labs.ReferenceRangeAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ReferenceRangeAgreementStatus.new) }
    }
}
