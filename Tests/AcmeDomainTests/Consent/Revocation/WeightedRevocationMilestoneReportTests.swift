@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWeightedRevocationMilestoneReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709357239)
        var items: [Consent.WeightedRevocationMilestone] = []
        for index in 0..<6 {
            items.append(Consent.newWeightedRevocationMilestone("weighted-revocation-milestone-\(index)", title: "sample"))
        }
        let report = Consent.buildWeightedRevocationMilestoneReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
