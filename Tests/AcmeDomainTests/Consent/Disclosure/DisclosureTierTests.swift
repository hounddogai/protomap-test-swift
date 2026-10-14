@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureTierTests {
    @Test func startsInNew() throws {
        let item = Consent.newDisclosureTier("code-71", title: "title-930")
        #expect(item.status == Consent.DisclosureTierStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Consent.newDisclosureTier("code-71", title: "title-930")
        try item.moveTo(Consent.DisclosureTierStatus.running)
        #expect(item.status == Consent.DisclosureTierStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newDisclosureTier("code-71", title: "title-930")
        item.status = Consent.DisclosureTierStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureTierStatus.new) }
    }
}
