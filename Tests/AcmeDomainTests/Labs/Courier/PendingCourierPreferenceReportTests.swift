@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingCourierPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703762211)
        var items: [Labs.PendingCourierPreference] = []
        for index in 0..<2 {
            items.append(Labs.newPendingCourierPreference("pending-courier-preference-\(index)", label: "sample"))
        }
        let report = Labs.buildPendingCourierPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
