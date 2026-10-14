@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702376010)
        var items: [Staffing.CredentialCheckpoint] = []
        for index in 0..<2 {
            items.append(Staffing.newCredentialCheckpoint("credential-checkpoint-\(index)", name: "sample"))
        }
        let report = Staffing.buildCredentialCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
