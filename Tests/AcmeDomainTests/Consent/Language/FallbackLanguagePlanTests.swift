@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackLanguagePlanTests {
    @Test func startsInIdle() throws {
        let item = Consent.newFallbackLanguagePlan("code-466", title: "title-232")
        #expect(item.status == Consent.FallbackLanguagePlanStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newFallbackLanguagePlan("code-466", title: "title-232")
        try item.moveTo(Consent.FallbackLanguagePlanStatus.warming)
        #expect(item.status == Consent.FallbackLanguagePlanStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newFallbackLanguagePlan("code-466", title: "title-232")
        item.status = Consent.FallbackLanguagePlanStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackLanguagePlanStatus.idle) }
    }
}
