@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialTemplateTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newManualDenialTemplate("code-110", title: "title-137")
        #expect(item.status == RevenueCycle.ManualDenialTemplateStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newManualDenialTemplate("code-110", title: "title-137")
        try item.moveTo(RevenueCycle.ManualDenialTemplateStatus.resolved)
        #expect(item.status == RevenueCycle.ManualDenialTemplateStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newManualDenialTemplate("code-110", title: "title-137")
        item.status = RevenueCycle.ManualDenialTemplateStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualDenialTemplateStatus.`open`) }
    }
}
