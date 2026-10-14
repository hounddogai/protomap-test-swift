@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingWitnessWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704756209)
        var items: [Consent.PendingWitnessWindow] = []
        for index in 0..<4 {
            items.append(Consent.newPendingWitnessWindow("pending-witness-window-\(index)", label: "sample"))
        }
        let report = Consent.buildPendingWitnessWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
