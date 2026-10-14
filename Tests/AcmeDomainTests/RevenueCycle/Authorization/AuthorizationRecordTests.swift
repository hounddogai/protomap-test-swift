@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationRecordTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newAuthorizationRecord("code-477", name: "name-524")
        #expect(item.status == RevenueCycle.AuthorizationRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = RevenueCycle.newAuthorizationRecord("code-477", name: "name-524")
        try item.moveTo(RevenueCycle.AuthorizationRecordStatus.done)
        #expect(item.status == RevenueCycle.AuthorizationRecordStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newAuthorizationRecord("code-477", name: "name-524")
        item.status = RevenueCycle.AuthorizationRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.AuthorizationRecordStatus.new) }
    }
}
