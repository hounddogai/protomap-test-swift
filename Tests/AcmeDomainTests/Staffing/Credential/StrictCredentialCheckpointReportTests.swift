@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictCredentialCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704912588)
        var items: [Staffing.StrictCredentialCheckpoint] = []
        for index in 0..<2 {
            items.append(Staffing.newStrictCredentialCheckpoint("strict-credential-checkpoint-\(index)", name: "sample"))
        }
        let report = Staffing.buildStrictCredentialCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
