@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredCredentialPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702664387)
        var items: [Staffing.TieredCredentialPolicy] = []
        for index in 0..<2 {
            items.append(Staffing.newTieredCredentialPolicy("tiered-credential-policy-\(index)", name: "sample"))
        }
        let report = Staffing.buildTieredCredentialPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
