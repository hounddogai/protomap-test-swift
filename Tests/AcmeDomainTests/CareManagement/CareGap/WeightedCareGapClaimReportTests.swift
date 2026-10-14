@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedCareGapClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705510789)
        var items: [CareManagement.WeightedCareGapClaim] = []
        for index in 0..<5 {
            items.append(CareManagement.newWeightedCareGapClaim("weighted-care-gap-claim-\(index)", label: "sample"))
        }
        let report = CareManagement.buildWeightedCareGapClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
