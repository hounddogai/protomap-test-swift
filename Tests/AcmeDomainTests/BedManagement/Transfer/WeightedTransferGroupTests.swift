@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferGroupTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newWeightedTransferGroup("code-561", title: "title-330")
        #expect(item.status == BedManagement.WeightedTransferGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = BedManagement.newWeightedTransferGroup("code-561", title: "title-330")
        try item.moveTo(BedManagement.WeightedTransferGroupStatus.archived)
        #expect(item.status == BedManagement.WeightedTransferGroupStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newWeightedTransferGroup("code-561", title: "title-330")
        item.status = BedManagement.WeightedTransferGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedTransferGroupStatus.`open`) }
    }
}
