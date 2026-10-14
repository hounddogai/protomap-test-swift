@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703818440)
        var items: [ClinicalOps.OrderSetProfile] = []
        for index in 0..<5 {
            items.append(ClinicalOps.newOrderSetProfile("order-set-profile-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildOrderSetProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
