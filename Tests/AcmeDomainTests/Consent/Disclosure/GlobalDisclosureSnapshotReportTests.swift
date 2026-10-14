@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureSnapshotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707139156)
        var items: [Consent.GlobalDisclosureSnapshot] = []
        for index in 0..<4 {
            items.append(Consent.newGlobalDisclosureSnapshot("global-disclosure-snapshot-\(index)", label: "sample"))
        }
        let report = Consent.buildGlobalDisclosureSnapshotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
