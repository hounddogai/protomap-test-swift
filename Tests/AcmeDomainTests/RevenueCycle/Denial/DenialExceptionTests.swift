@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialExceptionTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newDenialException("code-64", title: "title-751")
        #expect(item.status == RevenueCycle.DenialExceptionStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newDenialException("code-64", title: "title-751")
        try item.moveTo(RevenueCycle.DenialExceptionStatus.published)
        #expect(item.status == RevenueCycle.DenialExceptionStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newDenialException("code-64", title: "title-751")
        item.status = RevenueCycle.DenialExceptionStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialExceptionStatus.created) }
    }
}
