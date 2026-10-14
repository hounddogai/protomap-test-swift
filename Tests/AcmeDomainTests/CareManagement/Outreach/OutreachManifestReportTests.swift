@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementOutreachManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702648950)
        var items: [CareManagement.OutreachManifest] = []
        for index in 0..<4 {
            items.append(CareManagement.newOutreachManifest("outreach-manifest-\(index)", name: "sample"))
        }
        let report = CareManagement.buildOutreachManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
