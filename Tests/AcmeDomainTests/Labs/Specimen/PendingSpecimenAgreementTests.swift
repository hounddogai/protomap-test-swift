@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingSpecimenAgreementTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newPendingSpecimenAgreement("code-151", label: "label-350")
        #expect(item.status == Labs.PendingSpecimenAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCompleted() throws {
        let item = Labs.newPendingSpecimenAgreement("code-151", label: "label-350")
        try item.moveTo(Labs.PendingSpecimenAgreementStatus.completed)
        #expect(item.status == Labs.PendingSpecimenAgreementStatus.completed)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newPendingSpecimenAgreement("code-151", label: "label-350")
        item.status = Labs.PendingSpecimenAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PendingSpecimenAgreementStatus.planned) }
    }
}
