@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702243935)
        var items: [BedManagement.IsolationDigest] = []
        for index in 0..<3 {
            items.append(BedManagement.newIsolationDigest("isolation-digest-\(index)", title: "sample"))
        }
        let report = BedManagement.buildIsolationDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
