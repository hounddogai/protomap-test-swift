@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultConsentFormAdjustmentTests {
    @Test func startsInIdle() throws {
        let item = Consent.newDefaultConsentFormAdjustment("code-736", title: "title-403")
        #expect(item.status == Consent.DefaultConsentFormAdjustmentStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newDefaultConsentFormAdjustment("code-736", title: "title-403")
        try item.moveTo(Consent.DefaultConsentFormAdjustmentStatus.warming)
        #expect(item.status == Consent.DefaultConsentFormAdjustmentStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newDefaultConsentFormAdjustment("code-736", title: "title-403")
        item.status = Consent.DefaultConsentFormAdjustmentStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DefaultConsentFormAdjustmentStatus.idle) }
    }
}
