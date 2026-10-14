@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLenientRoundingTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703189764)
        var items: [ClinicalOps.LenientRoundingTemplate] = []
        for index in 0..<4 {
            items.append(ClinicalOps.newLenientRoundingTemplate("lenient-rounding-template-\(index)", name: "sample"))
        }
        let report = ClinicalOps.buildLenientRoundingTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
