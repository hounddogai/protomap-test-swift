@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCappedTransferThresholdTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newCappedTransferThreshold("code-357", title: "title-731")
        #expect(item.status == BedManagement.CappedTransferThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = BedManagement.newCappedTransferThreshold("code-357", title: "title-731")
        try item.moveTo(BedManagement.CappedTransferThresholdStatus.inReview)
        #expect(item.status == BedManagement.CappedTransferThresholdStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newCappedTransferThreshold("code-357", title: "title-731")
        item.status = BedManagement.CappedTransferThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.CappedTransferThresholdStatus.`open`) }
    }
}
