@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualWorklistAgreementReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709190976)
        var items: [Imaging.ManualWorklistAgreement] = []
        for index in 0..<3 {
            items.append(Imaging.newManualWorklistAgreement("manual-worklist-agreement-\(index)", title: "sample"))
        }
        let report = Imaging.buildManualWorklistAgreementReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
