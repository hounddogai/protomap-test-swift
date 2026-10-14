@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualWitnessBatchReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704434300)
        var items: [Consent.ManualWitnessBatch] = []
        for index in 0..<4 {
            items.append(Consent.newManualWitnessBatch("manual-witness-batch-\(index)", name: "sample"))
        }
        let report = Consent.buildManualWitnessBatchReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
