@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBundleTests {
    @Test func startsInNew() throws {
        let item = Consent.newDisclosureBundle("code-389", title: "title-634")
        #expect(item.status == Consent.DisclosureBundleStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToQueued() throws {
        let item = Consent.newDisclosureBundle("code-389", title: "title-634")
        try item.moveTo(Consent.DisclosureBundleStatus.queued)
        #expect(item.status == Consent.DisclosureBundleStatus.queued)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newDisclosureBundle("code-389", title: "title-634")
        item.status = Consent.DisclosureBundleStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureBundleStatus.new) }
    }
}
