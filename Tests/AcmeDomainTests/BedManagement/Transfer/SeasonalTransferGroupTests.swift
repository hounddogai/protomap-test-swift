@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalTransferGroupTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newSeasonalTransferGroup("code-394", title: "title-397")
        #expect(item.status == BedManagement.SeasonalTransferGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = BedManagement.newSeasonalTransferGroup("code-394", title: "title-397")
        try item.moveTo(BedManagement.SeasonalTransferGroupStatus.queued)
        #expect(item.status == BedManagement.SeasonalTransferGroupStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newSeasonalTransferGroup("code-394", title: "title-397")
        item.status = BedManagement.SeasonalTransferGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.SeasonalTransferGroupStatus.new) }
    }
}
