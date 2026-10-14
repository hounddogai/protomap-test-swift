@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationTemplateTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAuthorizationTemplate("code-221", name: "name-606")
        #expect(item.status == RevenueCycle.AuthorizationTemplateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newAuthorizationTemplate("code-221", name: "name-606")
        try item.moveTo(RevenueCycle.AuthorizationTemplateStatus.published)
        #expect(item.status == RevenueCycle.AuthorizationTemplateStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAuthorizationTemplate("code-221", name: "name-606")
        item.status = RevenueCycle.AuthorizationTemplateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationTemplateStatus.created) }
    }
}
