@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementCareGapBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702362251)
        var items: [CareManagement.CareGapBundle] = []
        for index in 0..<5 {
            items.append(CareManagement.newCareGapBundle("care-gap-bundle-\(index)", label: "sample"))
        }
        let report = CareManagement.buildCareGapBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
