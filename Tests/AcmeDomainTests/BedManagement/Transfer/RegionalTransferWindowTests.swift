@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRegionalTransferWindowTests {
    @Test func startsInProposed() throws {
        let item = BedManagement.newRegionalTransferWindow("code-191", title: "title-890")
        #expect(item.status == BedManagement.RegionalTransferWindowStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = BedManagement.newRegionalTransferWindow("code-191", title: "title-890")
        try item.moveTo(BedManagement.RegionalTransferWindowStatus.rejected)
        #expect(item.status == BedManagement.RegionalTransferWindowStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = BedManagement.newRegionalTransferWindow("code-191", title: "title-890")
        item.status = BedManagement.RegionalTransferWindowStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RegionalTransferWindowStatus.proposed) }
    }
}
