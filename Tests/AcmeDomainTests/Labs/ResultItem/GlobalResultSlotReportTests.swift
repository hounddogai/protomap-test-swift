@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalResultSlotReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1700393475)
        var items: [Labs.GlobalResultSlot] = []
        for index in 0..<4 {
            items.append(Labs.newGlobalResultSlot("global-result-slot-\(index)", name: "sample"))
        }
        let report = Labs.buildGlobalResultSlotReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 4)
        #expect(report.generatedAt == clock.now())
    }
}
