@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementFallbackAssessmentManifestReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1702860259)
        var items: [CareManagement.FallbackAssessmentManifest] = []
        for index in 0..<2 {
            items.append(CareManagement.newFallbackAssessmentManifest("fallback-assessment-manifest-\(index)", title: "sample"))
        }
        let report = CareManagement.buildFallbackAssessmentManifestReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 2)
        #expect(report.generatedAt == clock.now())
    }
}
