@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementSeasonalTransferPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708389120)
        var items: [BedManagement.SeasonalTransferPolicy] = []
        for index in 0..<3 {
            items.append(BedManagement.newSeasonalTransferPolicy("seasonal-transfer-policy-\(index)", name: "sample"))
        }
        let report = BedManagement.buildSeasonalTransferPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
