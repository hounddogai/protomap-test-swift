@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingDefaultCredentialClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703016396)
        var items: [Staffing.DefaultCredentialClaim] = []
        for index in 0..<4 {
            items.append(Staffing.newDefaultCredentialClaim("default-credential-claim-\(index)", title: "sample"))
        }
        let report = Staffing.buildDefaultCredentialClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
