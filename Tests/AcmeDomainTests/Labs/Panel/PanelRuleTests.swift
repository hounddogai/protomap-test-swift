@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRuleTests {
    @Test func startsInOpen() throws {
        let item = Labs.newPanelRule("code-382", name: "name-51")
        #expect(item.status == Labs.PanelRuleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Labs.newPanelRule("code-382", name: "name-51")
        try item.moveTo(Labs.PanelRuleStatus.inReview)
        #expect(item.status == Labs.PanelRuleStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Labs.newPanelRule("code-382", name: "name-51")
        item.status = Labs.PanelRuleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Labs.PanelRuleStatus.`open`) }
    }
}
