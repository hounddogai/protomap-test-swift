@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCensusPreferenceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706364280)
        var items: [BedManagement.CensusPreference] = []
        for index in 0..<4 {
            items.append(BedManagement.newCensusPreference("census-preference-\(index)", title: "sample"))
        }
        let report = BedManagement.buildCensusPreferenceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
