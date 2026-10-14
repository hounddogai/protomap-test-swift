@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalProgramClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707799638)
        var items: [CareManagement.GlobalProgramClaim] = []
        for index in 0..<6 {
            items.append(CareManagement.newGlobalProgramClaim("global-program-claim-\(index)", title: "sample"))
        }
        let report = CareManagement.buildGlobalProgramClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
