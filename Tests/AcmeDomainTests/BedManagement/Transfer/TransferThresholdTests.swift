@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferThresholdTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newTransferThreshold("code-876", name: "name-956")
        #expect(item.status == BedManagement.TransferThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToReopened() throws {
        let item = BedManagement.newTransferThreshold("code-876", name: "name-956")
        try item.moveTo(BedManagement.TransferThresholdStatus.reopened)
        #expect(item.status == BedManagement.TransferThresholdStatus.reopened)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newTransferThreshold("code-876", name: "name-956")
        item.status = BedManagement.TransferThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.TransferThresholdStatus.`open`) }
    }
}
