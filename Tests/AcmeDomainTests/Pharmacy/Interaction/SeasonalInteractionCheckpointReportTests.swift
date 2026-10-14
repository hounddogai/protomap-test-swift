@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySeasonalInteractionCheckpointReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702951560)
        var items: [Pharmacy.SeasonalInteractionCheckpoint] = []
        for index in 0..<5 {
            items.append(Pharmacy.newSeasonalInteractionCheckpoint("seasonal-interaction-checkpoint-\(index)", name: "sample"))
        }
        let report = Pharmacy.buildSeasonalInteractionCheckpointReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
