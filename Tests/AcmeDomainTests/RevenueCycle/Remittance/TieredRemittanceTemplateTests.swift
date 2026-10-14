@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceTemplateTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newTieredRemittanceTemplate("code-91", label: "label-56")
        #expect(item.status == RevenueCycle.TieredRemittanceTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = RevenueCycle.newTieredRemittanceTemplate("code-91", label: "label-56")
        try item.moveTo(RevenueCycle.TieredRemittanceTemplateStatus.inReview)
        #expect(item.status == RevenueCycle.TieredRemittanceTemplateStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newTieredRemittanceTemplate("code-91", label: "label-56")
        item.status = RevenueCycle.TieredRemittanceTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredRemittanceTemplateStatus.`open`) }
    }
}
