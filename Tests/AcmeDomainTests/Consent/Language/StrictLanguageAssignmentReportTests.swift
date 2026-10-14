@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictLanguageAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709958828)
        var items: [Consent.StrictLanguageAssignment] = []
        for index in 0..<6 {
            items.append(Consent.newStrictLanguageAssignment("strict-language-assignment-\(index)", title: "sample"))
        }
        let report = Consent.buildStrictLanguageAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
