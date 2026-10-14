@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedRemittanceTemplateTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newCappedRemittanceTemplate("code-166", name: "name-243")
        #expect(item.status == RevenueCycle.CappedRemittanceTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = RevenueCycle.newCappedRemittanceTemplate("code-166", name: "name-243")
        try item.moveTo(RevenueCycle.CappedRemittanceTemplateStatus.archived)
        #expect(item.status == RevenueCycle.CappedRemittanceTemplateStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newCappedRemittanceTemplate("code-166", name: "name-243")
        item.status = RevenueCycle.CappedRemittanceTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.CappedRemittanceTemplateStatus.`open`) }
    }
}
