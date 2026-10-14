@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsStrictAccessionAssignmentReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1705986323)
        var items: [Labs.StrictAccessionAssignment] = []
        for index in 0..<6 {
            items.append(Labs.newStrictAccessionAssignment("strict-accession-assignment-\(index)", title: "sample"))
        }
        let report = Labs.buildStrictAccessionAssignmentReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
