@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialProfileReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702537249)
        var items: [Staffing.CredentialProfile] = []
        for index in 0..<5 {
            items.append(Staffing.newCredentialProfile("credential-profile-\(index)", title: "sample"))
        }
        let report = Staffing.buildCredentialProfileReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
