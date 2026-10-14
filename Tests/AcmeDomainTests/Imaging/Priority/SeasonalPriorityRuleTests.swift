@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingSeasonalPriorityRuleTests {
    @Test func startsInNew() throws {
        let item = Imaging.newSeasonalPriorityRule("code-810", label: "label-373")
        #expect(item.status == Imaging.SeasonalPriorityRuleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = Imaging.newSeasonalPriorityRule("code-810", label: "label-373")
        try item.moveTo(Imaging.SeasonalPriorityRuleStatus.failed)
        #expect(item.status == Imaging.SeasonalPriorityRuleStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Imaging.newSeasonalPriorityRule("code-810", label: "label-373")
        item.status = Imaging.SeasonalPriorityRuleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.SeasonalPriorityRuleStatus.new) }
    }
}
