@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700777827)
        var items: [CareManagement.ScheduledCareGapPolicy] = []
        for index in 0..<5 {
            items.append(CareManagement.newScheduledCareGapPolicy("scheduled-care-gap-policy-\(index)", name: "sample"))
        }
        let report = CareManagement.buildScheduledCareGapPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
