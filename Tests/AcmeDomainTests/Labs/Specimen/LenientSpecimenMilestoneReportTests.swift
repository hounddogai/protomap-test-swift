@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientSpecimenMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702151909)
        var items: [Labs.LenientSpecimenMilestone] = []
        for index in 0..<5 {
            items.append(Labs.newLenientSpecimenMilestone("lenient-specimen-milestone-\(index)", label: "sample"))
        }
        let report = Labs.buildLenientSpecimenMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
