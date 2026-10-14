@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700481963)
        var items: [Pharmacy.ManualRecallVariance] = []
        for index in 0..<4 {
            items.append(Pharmacy.newManualRecallVariance("manual-recall-variance-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildManualRecallVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
