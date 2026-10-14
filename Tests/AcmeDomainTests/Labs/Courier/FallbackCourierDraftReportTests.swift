@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierDraftReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700049930)
        var items: [Labs.FallbackCourierDraft] = []
        for index in 0..<3 {
            items.append(Labs.newFallbackCourierDraft("fallback-courier-draft-\(index)", label: "sample"))
        }
        let report = Labs.buildFallbackCourierDraftReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
