@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyTargetTests {
    @Test func startsInIdle() throws {
        let item = Consent.newStrictProxyTarget("code-647", label: "label-82")
        #expect(item.status == Consent.StrictProxyTargetStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newStrictProxyTarget("code-647", label: "label-82")
        try item.moveTo(Consent.StrictProxyTargetStatus.ready)
        #expect(item.status == Consent.StrictProxyTargetStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newStrictProxyTarget("code-647", label: "label-82")
        item.status = Consent.StrictProxyTargetStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.StrictProxyTargetStatus.idle) }
    }
}
