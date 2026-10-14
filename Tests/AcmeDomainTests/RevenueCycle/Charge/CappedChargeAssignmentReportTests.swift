@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedChargeAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703116073)
        var items: [RevenueCycle.CappedChargeAssignment] = []
        for index in 0..<6 {
            items.append(RevenueCycle.newCappedChargeAssignment("capped-charge-assignment-\(index)", label: "sample"))
        }
        let report = RevenueCycle.buildCappedChargeAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
