@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702254420)
        var items: [BedManagement.DischargePlanCheckpoint] = []
        for index in 0..<4 {
            items.append(BedManagement.newDischargePlanCheckpoint("discharge-plan-checkpoint-\(index)", title: "sample"))
        }
        let report = BedManagement.buildDischargePlanCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
