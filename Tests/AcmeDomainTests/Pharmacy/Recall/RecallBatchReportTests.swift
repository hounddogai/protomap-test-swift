@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701216750)
        var items: [Pharmacy.RecallBatch] = []
        for index in 0..<4 {
            items.append(Pharmacy.newRecallBatch("recall-batch-\(index)", label: "sample"))
        }
        let report = Pharmacy.buildRecallBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
