@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureThresholdTests {
    @Test func startsInIdle() throws {
        let item = Consent.newDisclosureThreshold("code-917", name: "name-504")
        #expect(item.status == Consent.DisclosureThresholdStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newDisclosureThreshold("code-917", name: "name-504")
        try item.moveTo(Consent.DisclosureThresholdStatus.warming)
        #expect(item.status == Consent.DisclosureThresholdStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newDisclosureThreshold("code-917", name: "name-504")
        item.status = Consent.DisclosureThresholdStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureThresholdStatus.idle) }
    }
}
