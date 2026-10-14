@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationTargetTests {
    @Test func startsInCreated() throws {
        let item = Consent.newAdaptiveRevocationTarget("code-479", title: "title-346")
        #expect(item.status == Consent.AdaptiveRevocationTargetStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newAdaptiveRevocationTarget("code-479", title: "title-346")
        try item.moveTo(Consent.AdaptiveRevocationTargetStatus.published)
        #expect(item.status == Consent.AdaptiveRevocationTargetStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newAdaptiveRevocationTarget("code-479", title: "title-346")
        item.status = Consent.AdaptiveRevocationTargetStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveRevocationTargetStatus.created) }
    }
}
