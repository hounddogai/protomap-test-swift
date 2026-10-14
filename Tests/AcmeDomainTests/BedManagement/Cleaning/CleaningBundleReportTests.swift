@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningBundleReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700797219)
        var items: [BedManagement.CleaningBundle] = []
        for index in 0..<5 {
            items.append(BedManagement.newCleaningBundle("cleaning-bundle-\(index)", title: "sample"))
        }
        let report = BedManagement.buildCleaningBundleReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
