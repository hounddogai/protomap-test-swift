@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveDisclosureEntryTests {
    @Test func startsInNew() throws {
        let item = Consent.newAdaptiveDisclosureEntry("code-284", name: "name-259")
        #expect(item.status == Consent.AdaptiveDisclosureEntryStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newAdaptiveDisclosureEntry("code-284", name: "name-259")
        try item.moveTo(Consent.AdaptiveDisclosureEntryStatus.running)
        #expect(item.status == Consent.AdaptiveDisclosureEntryStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newAdaptiveDisclosureEntry("code-284", name: "name-259")
        item.status = Consent.AdaptiveDisclosureEntryStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveDisclosureEntryStatus.new) }
    }
}
