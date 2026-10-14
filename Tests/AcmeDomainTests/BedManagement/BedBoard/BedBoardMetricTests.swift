@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardMetricTests {
    @Test func startsInDraft() throws {
        let item = BedManagement.newBedBoardMetric("code-633", name: "name-957")
        #expect(item.status == BedManagement.BedBoardMetricStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToSuspended() throws {
        let item = BedManagement.newBedBoardMetric("code-633", name: "name-957")
        try item.moveTo(BedManagement.BedBoardMetricStatus.suspended)
        #expect(item.status == BedManagement.BedBoardMetricStatus.suspended)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = BedManagement.newBedBoardMetric("code-633", name: "name-957")
        item.status = BedManagement.BedBoardMetricStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.BedBoardMetricStatus.draft) }
    }
}
