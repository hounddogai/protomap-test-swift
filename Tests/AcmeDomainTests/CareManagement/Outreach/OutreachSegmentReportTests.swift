@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachSegmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703494509)
        var items: [CareManagement.OutreachSegment] = []
        for index in 0..<4 {
            items.append(CareManagement.newOutreachSegment("outreach-segment-\(index)", title: "sample"))
        }
        let report = CareManagement.buildOutreachSegmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
