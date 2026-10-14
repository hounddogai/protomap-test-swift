@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityRuleTests {
    @Test func startsInOpen() throws {
        let item = Imaging.newPriorityRule("code-935", label: "label-281")
        #expect(item.status == Imaging.PriorityRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Imaging.newPriorityRule("code-935", label: "label-281")
        try item.moveTo(Imaging.PriorityRuleStatus.resolved)
        #expect(item.status == Imaging.PriorityRuleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Imaging.newPriorityRule("code-935", label: "label-281")
        item.status = Imaging.PriorityRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.PriorityRuleStatus.`open`) }
    }
}
