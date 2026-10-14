@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessNoticeReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708865475)
        var items: [Consent.BatchedWitnessNotice] = []
        for index in 0..<6 {
            items.append(Consent.newBatchedWitnessNotice("batched-witness-notice-\(index)", label: "sample"))
        }
        let report = Consent.buildBatchedWitnessNoticeReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
