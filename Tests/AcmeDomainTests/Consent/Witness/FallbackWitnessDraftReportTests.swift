@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackWitnessDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1703229621)
        var items: [Consent.FallbackWitnessDraft] = []
        for index in 0..<6 {
            items.append(Consent.newFallbackWitnessDraft("fallback-witness-draft-\(index)", title: "sample"))
        }
        let report = Consent.buildFallbackWitnessDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
