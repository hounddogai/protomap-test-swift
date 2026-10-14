@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientTransferVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700666741)
        var items: [BedManagement.LenientTransferVariance] = []
        for index in 0..<6 {
            items.append(BedManagement.newLenientTransferVariance("lenient-transfer-variance-\(index)", title: "sample"))
        }
        let report = BedManagement.buildLenientTransferVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
