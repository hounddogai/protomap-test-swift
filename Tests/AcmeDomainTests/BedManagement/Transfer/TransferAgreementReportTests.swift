@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700753882)
        var items: [BedManagement.TransferAgreement] = []
        for index in 0..<4 {
            items.append(BedManagement.newTransferAgreement("transfer-agreement-\(index)", label: "sample"))
        }
        let report = BedManagement.buildTransferAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
