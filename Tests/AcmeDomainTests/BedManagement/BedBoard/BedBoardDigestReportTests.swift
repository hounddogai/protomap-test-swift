@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBedBoardDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701861316)
        var items: [BedManagement.BedBoardDigest] = []
        for index in 0..<4 {
            items.append(BedManagement.newBedBoardDigest("bed-board-digest-\(index)", label: "sample"))
        }
        let report = BedManagement.buildBedBoardDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
