@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessThresholdReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709716530)
        var items: [Consent.WitnessThreshold] = []
        for index in 0..<5 {
            items.append(Consent.newWitnessThreshold("witness-threshold-\(index)", title: "sample"))
        }
        let report = Consent.buildWitnessThresholdReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
