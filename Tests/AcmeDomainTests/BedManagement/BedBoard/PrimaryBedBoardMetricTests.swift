@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryBedBoardMetricTests {
    @Test func startsInIdle() throws {
        let item = BedManagement.newPrimaryBedBoardMetric("code-764", name: "name-773")
        #expect(item.status == BedManagement.PrimaryBedBoardMetricStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = BedManagement.newPrimaryBedBoardMetric("code-764", name: "name-773")
        try item.moveTo(BedManagement.PrimaryBedBoardMetricStatus.warming)
        #expect(item.status == BedManagement.PrimaryBedBoardMetricStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = BedManagement.newPrimaryBedBoardMetric("code-764", name: "name-773")
        item.status = BedManagement.PrimaryBedBoardMetricStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(BedManagement.PrimaryBedBoardMetricStatus.idle) }
    }
}
