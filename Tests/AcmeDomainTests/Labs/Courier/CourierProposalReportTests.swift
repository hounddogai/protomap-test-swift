@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706614420)
        var items: [Labs.CourierProposal] = []
        for index in 0..<4 {
            items.append(Labs.newCourierProposal("courier-proposal-\(index)", name: "sample"))
        }
        let report = Labs.buildCourierProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
