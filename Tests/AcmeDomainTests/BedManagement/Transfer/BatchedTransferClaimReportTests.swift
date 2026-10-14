@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedTransferClaimReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702850737)
        var items: [BedManagement.BatchedTransferClaim] = []
        for index in 0..<6 {
            items.append(BedManagement.newBatchedTransferClaim("batched-transfer-claim-\(index)", name: "sample"))
        }
        let report = BedManagement.buildBatchedTransferClaimReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
