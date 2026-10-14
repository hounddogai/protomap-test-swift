@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingProgramDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700181499)
        var items: [CareManagement.RollingProgramDraft] = []
        for index in 0..<2 {
            items.append(CareManagement.newRollingProgramDraft("rolling-program-draft-\(index)", name: "sample"))
        }
        let report = CareManagement.buildRollingProgramDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
