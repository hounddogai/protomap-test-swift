@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialGroupTests {
    @Test func startsInNew() throws {
        let item = RevenueCycle.newDenialGroup("code-862", title: "title-252")
        #expect(item.status == RevenueCycle.DenialGroupStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToFailed() throws {
        let item = RevenueCycle.newDenialGroup("code-862", title: "title-252")
        try item.moveTo(RevenueCycle.DenialGroupStatus.failed)
        #expect(item.status == RevenueCycle.DenialGroupStatus.failed)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = RevenueCycle.newDenialGroup("code-862", title: "title-252")
        item.status = RevenueCycle.DenialGroupStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.DenialGroupStatus.new) }
    }
}
