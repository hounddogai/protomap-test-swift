@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedReferenceRangeAgreementTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newCappedReferenceRangeAgreement("code-748", name: "name-913")
        #expect(item.status == Labs.CappedReferenceRangeAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newCappedReferenceRangeAgreement("code-748", name: "name-913")
        try item.moveTo(Labs.CappedReferenceRangeAgreementStatus.completed)
        #expect(item.status == Labs.CappedReferenceRangeAgreementStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newCappedReferenceRangeAgreement("code-748", name: "name-913")
        item.status = Labs.CappedReferenceRangeAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.CappedReferenceRangeAgreementStatus.planned) }
    }
}
