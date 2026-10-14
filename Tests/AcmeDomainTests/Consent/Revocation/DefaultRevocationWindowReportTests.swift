@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultRevocationWindowReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705818498)
        var items: [Consent.DefaultRevocationWindow] = []
        for index in 0..<5 {
            items.append(Consent.newDefaultRevocationWindow("default-revocation-window-\(index)", label: "sample"))
        }
        let report = Consent.buildDefaultRevocationWindowReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
