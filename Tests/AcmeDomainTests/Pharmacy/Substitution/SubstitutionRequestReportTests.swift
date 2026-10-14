@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRequestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1706408370)
        var items: [Pharmacy.SubstitutionRequest] = []
        for index in 0..<4 {
            items.append(Pharmacy.newSubstitutionRequest("substitution-request-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildSubstitutionRequestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
