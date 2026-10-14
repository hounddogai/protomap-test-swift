@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationExceptionTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newAuthorizationException("code-959", title: "title-996")
        #expect(item.status == RevenueCycle.AuthorizationExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newAuthorizationException("code-959", title: "title-996")
        try item.moveTo(RevenueCycle.AuthorizationExceptionStatus.published)
        #expect(item.status == RevenueCycle.AuthorizationExceptionStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newAuthorizationException("code-959", title: "title-996")
        item.status = RevenueCycle.AuthorizationExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationExceptionStatus.created) }
    }
}
