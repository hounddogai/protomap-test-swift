@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceTemplateTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newRemittanceTemplate("code-424", title: "title-936")
        #expect(item.status == RevenueCycle.RemittanceTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newRemittanceTemplate("code-424", title: "title-936")
        try item.moveTo(RevenueCycle.RemittanceTemplateStatus.done)
        #expect(item.status == RevenueCycle.RemittanceTemplateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newRemittanceTemplate("code-424", title: "title-936")
        item.status = RevenueCycle.RemittanceTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RemittanceTemplateStatus.new) }
    }
}
