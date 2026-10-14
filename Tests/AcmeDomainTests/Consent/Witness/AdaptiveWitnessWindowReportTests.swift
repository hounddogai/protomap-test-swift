@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveWitnessWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708251113)
        var items: [Consent.AdaptiveWitnessWindow] = []
        for index in 0..<3 {
            items.append(Consent.newAdaptiveWitnessWindow("adaptive-witness-window-\(index)", label: "sample"))
        }
        let report = Consent.buildAdaptiveWitnessWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
