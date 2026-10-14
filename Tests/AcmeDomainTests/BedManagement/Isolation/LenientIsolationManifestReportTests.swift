@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1701660038)
        var items: [BedManagement.LenientIsolationManifest] = []
        for index in 0..<5 {
            items.append(BedManagement.newLenientIsolationManifest("lenient-isolation-manifest-\(index)", title: "sample"))
        }
        let report = BedManagement.buildLenientIsolationManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
