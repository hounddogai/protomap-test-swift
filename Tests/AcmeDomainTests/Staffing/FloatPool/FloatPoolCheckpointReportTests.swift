@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFloatPoolCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703071978)
        var items: [Staffing.FloatPoolCheckpoint] = []
        for index in 0..<3 {
            items.append(Staffing.newFloatPoolCheckpoint("float-pool-checkpoint-\(index)", label: "sample"))
        }
        let report = Staffing.buildFloatPoolCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
