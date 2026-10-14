@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLenientResultAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705414895)
        var items: [Labs.LenientResultAgreement] = []
        for index in 0..<3 {
            items.append(Labs.newLenientResultAgreement("lenient-result-agreement-\(index)", title: "sample"))
        }
        let report = Labs.buildLenientResultAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
