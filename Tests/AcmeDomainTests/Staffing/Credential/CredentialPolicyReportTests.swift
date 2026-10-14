@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702339305)
        var items: [Staffing.CredentialPolicy] = []
        for index in 0..<4 {
            items.append(Staffing.newCredentialPolicy("credential-policy-\(index)", title: "sample"))
        }
        let report = Staffing.buildCredentialPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
