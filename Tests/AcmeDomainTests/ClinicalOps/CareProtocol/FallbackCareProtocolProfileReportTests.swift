@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705929923)
        var items: [ClinicalOps.FallbackCareProtocolProfile] = []
        for index in 0..<2 {
            items.append(ClinicalOps.newFallbackCareProtocolProfile("fallback-care-protocol-profile-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildFallbackCareProtocolProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
