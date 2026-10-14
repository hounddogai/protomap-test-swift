@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimProfileTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newClaimProfile("code-503", name: "name-361")
        #expect(item.status == RevenueCycle.ClaimProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newClaimProfile("code-503", name: "name-361")
        try item.moveTo(RevenueCycle.ClaimProfileStatus.resolved)
        #expect(item.status == RevenueCycle.ClaimProfileStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newClaimProfile("code-503", name: "name-361")
        item.status = RevenueCycle.ClaimProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ClaimProfileStatus.`open`) }
    }
}
