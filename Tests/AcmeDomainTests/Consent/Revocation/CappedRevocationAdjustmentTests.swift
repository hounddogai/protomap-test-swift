@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationAdjustmentTests {
    @Test func startsInPlanned() throws {
        let item = Consent.newCappedRevocationAdjustment("code-626", label: "label-982")
        #expect(item.status == Consent.CappedRevocationAdjustmentStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Consent.newCappedRevocationAdjustment("code-626", label: "label-982")
        try item.moveTo(Consent.CappedRevocationAdjustmentStatus.inProgress)
        #expect(item.status == Consent.CappedRevocationAdjustmentStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Consent.newCappedRevocationAdjustment("code-626", label: "label-982")
        item.status = Consent.CappedRevocationAdjustmentStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedRevocationAdjustmentStatus.planned) }
    }
}
