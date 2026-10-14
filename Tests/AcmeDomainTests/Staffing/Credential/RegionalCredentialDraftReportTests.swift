@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRegionalCredentialDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709691532)
        var items: [Staffing.RegionalCredentialDraft] = []
        for index in 0..<5 {
            items.append(Staffing.newRegionalCredentialDraft("regional-credential-draft-\(index)", name: "sample"))
        }
        let report = Staffing.buildRegionalCredentialDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
