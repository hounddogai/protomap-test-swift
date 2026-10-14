@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackFloatPoolCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709058936)
        var items: [Staffing.FallbackFloatPoolCheckpoint] = []
        for index in 0..<2 {
            items.append(Staffing.newFallbackFloatPoolCheckpoint("fallback-float-pool-checkpoint-\(index)", label: "sample"))
        }
        let report = Staffing.buildFallbackFloatPoolCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
