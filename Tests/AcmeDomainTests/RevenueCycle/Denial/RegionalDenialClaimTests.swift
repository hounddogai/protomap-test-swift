@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalDenialClaimTests {
    @Test func startsInDraft() throws {
        let item = RevenueCycle.newRegionalDenialClaim("code-587", title: "title-845")
        #expect(item.status == RevenueCycle.RegionalDenialClaimStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToClosed() throws {
        let item = RevenueCycle.newRegionalDenialClaim("code-587", title: "title-845")
        try item.moveTo(RevenueCycle.RegionalDenialClaimStatus.closed)
        #expect(item.status == RevenueCycle.RegionalDenialClaimStatus.closed)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = RevenueCycle.newRegionalDenialClaim("code-587", title: "title-845")
        item.status = RevenueCycle.RegionalDenialClaimStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalDenialClaimStatus.draft) }
    }
}
