@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferTargetTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newWeightedTransferTarget("code-220", label: "label-789")
        #expect(item.status == BedManagement.WeightedTransferTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newWeightedTransferTarget("code-220", label: "label-789")
        try item.moveTo(BedManagement.WeightedTransferTargetStatus.resolved)
        #expect(item.status == BedManagement.WeightedTransferTargetStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newWeightedTransferTarget("code-220", label: "label-789")
        item.status = BedManagement.WeightedTransferTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.WeightedTransferTargetStatus.`open`) }
    }
}
