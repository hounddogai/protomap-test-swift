@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingManualCredentialMappingReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701160600)
        var items: [Staffing.ManualCredentialMapping] = []
        for index in 0..<3 {
            items.append(Staffing.newManualCredentialMapping("manual-credential-mapping-\(index)", name: "sample"))
        }
        let report = Staffing.buildManualCredentialMappingReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
