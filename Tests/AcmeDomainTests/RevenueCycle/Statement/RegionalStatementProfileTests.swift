@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementProfileTests {
    @Test func startsInCreated() throws {
        let item = RevenueCycle.newRegionalStatementProfile("code-74", title: "title-602")
        #expect(item.status == RevenueCycle.RegionalStatementProfileStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = RevenueCycle.newRegionalStatementProfile("code-74", title: "title-602")
        try item.moveTo(RevenueCycle.RegionalStatementProfileStatus.published)
        #expect(item.status == RevenueCycle.RegionalStatementProfileStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = RevenueCycle.newRegionalStatementProfile("code-74", title: "title-602")
        item.status = RevenueCycle.RegionalStatementProfileStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RegionalStatementProfileStatus.created) }
    }
}
