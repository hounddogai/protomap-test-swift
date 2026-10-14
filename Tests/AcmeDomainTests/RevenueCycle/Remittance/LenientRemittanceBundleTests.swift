@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLenientRemittanceBundleTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newLenientRemittanceBundle("code-418", title: "title-784")
        #expect(item.status == RevenueCycle.LenientRemittanceBundleStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToPending() throws {
        let item = RevenueCycle.newLenientRemittanceBundle("code-418", title: "title-784")
        try item.moveTo(RevenueCycle.LenientRemittanceBundleStatus.pending)
        #expect(item.status == RevenueCycle.LenientRemittanceBundleStatus.pending)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newLenientRemittanceBundle("code-418", title: "title-784")
        item.status = RevenueCycle.LenientRemittanceBundleStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.LenientRemittanceBundleStatus.draft) }
    }
}
