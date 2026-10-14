@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureProfileTests {
    @Test func startsInIdle() throws {
        let item = Consent.newFallbackDisclosureProfile("code-699", title: "title-370")
        #expect(item.status == Consent.FallbackDisclosureProfileStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newFallbackDisclosureProfile("code-699", title: "title-370")
        try item.moveTo(Consent.FallbackDisclosureProfileStatus.ready)
        #expect(item.status == Consent.FallbackDisclosureProfileStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newFallbackDisclosureProfile("code-699", title: "title-370")
        item.status = Consent.FallbackDisclosureProfileStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.FallbackDisclosureProfileStatus.idle) }
    }
}
