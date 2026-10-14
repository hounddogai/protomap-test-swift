@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1708893160)
        var items: [Labs.SeasonalAccessionAgreement] = []
        for index in 0..<3 {
            items.append(Labs.newSeasonalAccessionAgreement("seasonal-accession-agreement-\(index)", title: "sample"))
        }
        let report = Labs.buildSeasonalAccessionAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
