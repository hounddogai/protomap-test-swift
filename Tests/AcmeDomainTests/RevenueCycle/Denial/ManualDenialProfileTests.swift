@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialProfileTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newManualDenialProfile("code-260", title: "title-900")
        #expect(item.status == RevenueCycle.ManualDenialProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newManualDenialProfile("code-260", title: "title-900")
        try item.moveTo(RevenueCycle.ManualDenialProfileStatus.resolved)
        #expect(item.status == RevenueCycle.ManualDenialProfileStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newManualDenialProfile("code-260", title: "title-900")
        item.status = RevenueCycle.ManualDenialProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualDenialProfileStatus.`open`) }
    }
}
