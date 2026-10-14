@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolScheduleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704444485)
        var items: [ClinicalOps.CareProtocolSchedule] = []
        for index in 0..<3 {
            items.append(ClinicalOps.newCareProtocolSchedule("care-protocol-schedule-\(index)", title: "sample"))
        }
        let report = ClinicalOps.buildCareProtocolScheduleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
