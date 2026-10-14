@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardBundleTests {
    @Test func startsInNew() throws {
        let item = BedManagement.newBedBoardBundle("code-566", label: "label-376")
        #expect(item.status == BedManagement.BedBoardBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = BedManagement.newBedBoardBundle("code-566", label: "label-376")
        try item.moveTo(BedManagement.BedBoardBundleStatus.running)
        #expect(item.status == BedManagement.BedBoardBundleStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = BedManagement.newBedBoardBundle("code-566", label: "label-376")
        item.status = BedManagement.BedBoardBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardBundleStatus.new) }
    }
}
