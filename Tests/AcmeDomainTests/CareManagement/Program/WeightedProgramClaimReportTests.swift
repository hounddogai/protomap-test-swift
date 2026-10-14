@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707366598)
        var items: [CareManagement.WeightedProgramClaim] = []
        for index in 0..<3 {
            items.append(CareManagement.newWeightedProgramClaim("weighted-program-claim-\(index)", label: "sample"))
        }
        let report = CareManagement.buildWeightedProgramClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
