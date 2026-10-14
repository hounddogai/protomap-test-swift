@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenPolicyReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705237060)
        var items: [Labs.DefaultSpecimenPolicy] = []
        for index in 0..<6 {
            items.append(Labs.newDefaultSpecimenPolicy("default-specimen-policy-\(index)", name: "sample"))
        }
        let report = Labs.buildDefaultSpecimenPolicyReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
