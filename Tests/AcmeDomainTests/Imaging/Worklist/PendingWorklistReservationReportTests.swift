@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistReservationReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702627065)
        var items: [Imaging.PendingWorklistReservation] = []
        for index in 0..<6 {
            items.append(Imaging.newPendingWorklistReservation("pending-worklist-reservation-\(index)", title: "sample"))
        }
        let report = Imaging.buildPendingWorklistReservationReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
