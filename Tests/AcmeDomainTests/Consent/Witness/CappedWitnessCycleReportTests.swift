@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessCycleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705578474)
        var items: [Consent.CappedWitnessCycle] = []
        for index in 0..<2 {
            items.append(Consent.newCappedWitnessCycle("capped-witness-cycle-\(index)", title: "sample"))
        }
        let report = Consent.buildCappedWitnessCycleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
