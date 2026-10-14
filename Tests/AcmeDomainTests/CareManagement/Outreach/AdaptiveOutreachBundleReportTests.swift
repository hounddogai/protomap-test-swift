@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveOutreachBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703071314)
        var items: [CareManagement.AdaptiveOutreachBundle] = []
        for index in 0..<5 {
            items.append(CareManagement.newAdaptiveOutreachBundle("adaptive-outreach-bundle-\(index)", title: "sample"))
        }
        let report = CareManagement.buildAdaptiveOutreachBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
