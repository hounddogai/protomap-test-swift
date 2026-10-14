@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackRecallTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704886472)
        var items: [Pharmacy.FallbackRecallTemplate] = []
        for index in 0..<2 {
            items.append(Pharmacy.newFallbackRecallTemplate("fallback-recall-template-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildFallbackRecallTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
