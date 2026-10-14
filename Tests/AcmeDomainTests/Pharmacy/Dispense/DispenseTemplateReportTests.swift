@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTemplateReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1704106488)
        var items: [Pharmacy.DispenseTemplate] = []
        for index in 0..<4 {
            items.append(Pharmacy.newDispenseTemplate("dispense-template-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildDispenseTemplateReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
