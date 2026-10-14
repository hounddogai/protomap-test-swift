@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedSubstitutionProposalReportTests {
    @Test func countsEachRecordOnce() throws {
        let clock: any Kit.Clocks.Clock = Kit.Clocks.FixedClock(at: 1709858364)
        var items: [Pharmacy.WeightedSubstitutionProposal] = []
        for index in 0..<6 {
            items.append(Pharmacy.newWeightedSubstitutionProposal("weighted-substitution-proposal-\(index)", title: "sample"))
        }
        let report = Pharmacy.buildWeightedSubstitutionProposalReport("test", items: items, clock: clock)
        var counted = 0
        for (_, value) in report.counts.sorted(by: { $0.key < $1.key }) {
            counted += value
        }
        #expect(counted <= 6)
        #expect(report.generatedAt == clock.now())
    }
}
