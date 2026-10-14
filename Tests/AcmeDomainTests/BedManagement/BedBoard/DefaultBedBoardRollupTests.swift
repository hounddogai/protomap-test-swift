@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultBedBoardRollupTests {
    @Test func startsInRequested() throws {
        let item = BedManagement.newDefaultBedBoardRollup("code-909", label: "label-811")
        #expect(item.status == BedManagement.DefaultBedBoardRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = BedManagement.newDefaultBedBoardRollup("code-909", label: "label-811")
        try item.moveTo(BedManagement.DefaultBedBoardRollupStatus.expired)
        #expect(item.status == BedManagement.DefaultBedBoardRollupStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = BedManagement.newDefaultBedBoardRollup("code-909", label: "label-811")
        item.status = BedManagement.DefaultBedBoardRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.DefaultBedBoardRollupStatus.requested) }
    }
}
