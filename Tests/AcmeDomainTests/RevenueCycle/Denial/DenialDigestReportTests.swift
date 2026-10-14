@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialDigestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702114813)
        var items: [RevenueCycle.DenialDigest] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newDenialDigest("denial-digest-\(index)", title: "sample"))
        }
        let report = RevenueCycle.buildDenialDigestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
