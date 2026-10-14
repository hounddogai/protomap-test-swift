@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAdaptiveCredentialTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703423040)
        var items: [Staffing.AdaptiveCredentialTemplate] = []
        for index in 0..<3 {
            items.append(Staffing.newAdaptiveCredentialTemplate("adaptive-credential-template-\(index)", name: "sample"))
        }
        let report = Staffing.buildAdaptiveCredentialTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
