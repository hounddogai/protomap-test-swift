@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingTransferSegmentTests {
    @Test func startsInOpen() throws {
        let item = BedManagement.newRollingTransferSegment("code-857", name: "name-841")
        #expect(item.status == BedManagement.RollingTransferSegmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = BedManagement.newRollingTransferSegment("code-857", name: "name-841")
        try item.moveTo(BedManagement.RollingTransferSegmentStatus.resolved)
        #expect(item.status == BedManagement.RollingTransferSegmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = BedManagement.newRollingTransferSegment("code-857", name: "name-841")
        item.status = BedManagement.RollingTransferSegmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.RollingTransferSegmentStatus.`open`) }
    }
}
