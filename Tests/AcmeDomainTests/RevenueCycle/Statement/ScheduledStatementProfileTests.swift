@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledStatementProfileTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newScheduledStatementProfile("code-326", name: "name-763")
        #expect(item.status == RevenueCycle.ScheduledStatementProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newScheduledStatementProfile("code-326", name: "name-763")
        try item.moveTo(RevenueCycle.ScheduledStatementProfileStatus.resolved)
        #expect(item.status == RevenueCycle.ScheduledStatementProfileStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newScheduledStatementProfile("code-326", name: "name-763")
        item.status = RevenueCycle.ScheduledStatementProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ScheduledStatementProfileStatus.`open`) }
    }
}
