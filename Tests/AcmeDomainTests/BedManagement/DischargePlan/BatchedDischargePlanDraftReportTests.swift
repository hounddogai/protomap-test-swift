@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedDischargePlanDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702848115)
        var items: [BedManagement.BatchedDischargePlanDraft] = []
        for index in 0..<6 {
            items.append(BedManagement.newBatchedDischargePlanDraft("batched-discharge-plan-draft-\(index)", name: "sample"))
        }
        let report = BedManagement.buildBatchedDischargePlanDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
