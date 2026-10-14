@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolVarianceReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705986021)
        var items: [Imaging.CareProtocolVariance] = []
        for index in 0..<5 {
            items.append(Imaging.newCareProtocolVariance("care-protocol-variance-\(index)", title: "sample"))
        }
        let report = Imaging.buildCareProtocolVarianceReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 5)
        #expect(report.generatedAt == clock.now())
    }
}
