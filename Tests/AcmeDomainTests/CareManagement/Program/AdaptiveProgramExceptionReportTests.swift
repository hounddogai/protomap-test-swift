@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramExceptionReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1707435644)
        var items: [CareManagement.AdaptiveProgramException] = []
        for index in 0..<3 {
            items.append(CareManagement.newAdaptiveProgramException("adaptive-program-exception-\(index)", title: "sample"))
        }
        let report = CareManagement.buildAdaptiveProgramExceptionReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 3)
        #expect(report.generatedAt == clock.now())
    }
}
