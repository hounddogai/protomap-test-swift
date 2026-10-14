@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferAgreementTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newWeightedTransferAgreement("code-307", title: "title-232")
        #expect(item.status == BedManagement.WeightedTransferAgreementStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToGranted() throws {
        let item = BedManagement.newWeightedTransferAgreement("code-307", title: "title-232")
        try item.moveTo(BedManagement.WeightedTransferAgreementStatus.granted)
        #expect(item.status == BedManagement.WeightedTransferAgreementStatus.granted)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newWeightedTransferAgreement("code-307", title: "title-232")
        item.status = BedManagement.WeightedTransferAgreementStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedTransferAgreementStatus.requested) }
    }
}
