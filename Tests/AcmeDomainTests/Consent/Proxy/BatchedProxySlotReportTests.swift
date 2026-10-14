@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxySlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707556451)
        var items: [Consent.BatchedProxySlot] = []
        for index in 0..<5 {
            items.append(Consent.newBatchedProxySlot("batched-proxy-slot-\(index)", label: "sample"))
        }
        let report = Consent.buildBatchedProxySlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
