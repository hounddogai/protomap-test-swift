@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredDenialTemplateTests {
    @Test func startsInIdle() throws {
        let item = RevenueCycle.newTieredDenialTemplate("code-236", title: "title-679")
        #expect(item.status == RevenueCycle.TieredDenialTemplateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = RevenueCycle.newTieredDenialTemplate("code-236", title: "title-679")
        try item.moveTo(RevenueCycle.TieredDenialTemplateStatus.warming)
        #expect(item.status == RevenueCycle.TieredDenialTemplateStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = RevenueCycle.newTieredDenialTemplate("code-236", title: "title-679")
        item.status = RevenueCycle.TieredDenialTemplateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredDenialTemplateStatus.idle) }
    }
}
