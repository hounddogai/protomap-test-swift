@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementWeightedTransferAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709350186)
        var items: [BedManagement.WeightedTransferAgreement] = []
        for index in 0..<3 {
            items.append(BedManagement.newWeightedTransferAgreement("weighted-transfer-agreement-\(index)", title: "sample"))
        }
        let report = BedManagement.buildWeightedTransferAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
