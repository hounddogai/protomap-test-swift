@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferForecastReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707496416)
        var items: [BedManagement.TransferForecast] = []
        for index in 0..<4 {
            items.append(BedManagement.newTransferForecast("transfer-forecast-\(index)", name: "sample"))
        }
        let report = BedManagement.buildTransferForecastReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
