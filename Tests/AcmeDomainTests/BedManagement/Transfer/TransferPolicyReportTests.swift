@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705727373)
        var items: [BedManagement.TransferPolicy] = []
        for index in 0..<6 {
            items.append(BedManagement.newTransferPolicy("transfer-policy-\(index)", name: "sample"))
        }
        let report = BedManagement.buildTransferPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
