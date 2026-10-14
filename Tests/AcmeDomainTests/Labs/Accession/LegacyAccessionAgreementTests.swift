@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionAgreementTests {
    @Test func startsInPlanned() throws {
        let item = Labs.newLegacyAccessionAgreement("code-652", label: "label-214")
        #expect(item.status == Labs.LegacyAccessionAgreementStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = Labs.newLegacyAccessionAgreement("code-652", label: "label-214")
        try item.moveTo(Labs.LegacyAccessionAgreementStatus.scheduled)
        #expect(item.status == Labs.LegacyAccessionAgreementStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Labs.newLegacyAccessionAgreement("code-652", label: "label-214")
        item.status = Labs.LegacyAccessionAgreementStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Labs.LegacyAccessionAgreementStatus.planned) }
    }
}
