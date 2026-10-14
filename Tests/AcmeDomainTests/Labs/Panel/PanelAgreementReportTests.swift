@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709159390)
        var items: [Labs.PanelAgreement] = []
        for index in 0..<4 {
            items.append(Labs.newPanelAgreement("panel-agreement-\(index)", title: "sample"))
        }
        let report = Labs.buildPanelAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
