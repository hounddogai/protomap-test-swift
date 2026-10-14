@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementGroupTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newRollingStatementGroup("code-466", title: "title-299")
        #expect(item.status == RevenueCycle.RollingStatementGroupStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newRollingStatementGroup("code-466", title: "title-299")
        try item.moveTo(RevenueCycle.RollingStatementGroupStatus.resolved)
        #expect(item.status == RevenueCycle.RollingStatementGroupStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newRollingStatementGroup("code-466", title: "title-299")
        item.status = RevenueCycle.RollingStatementGroupStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.RollingStatementGroupStatus.`open`) }
    }
}
