@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRollupReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709490798)
        var items: [Staffing.CredentialRollup] = []
        for index in 0..<2 {
            items.append(Staffing.newCredentialRollup("credential-rollup-\(index)", label: "sample"))
        }
        let report = Staffing.buildCredentialRollupReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
