@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureMappingTests {
    @Test func startsInIdle() throws {
        let item = Consent.newDisclosureMapping("code-406", title: "title-881")
        #expect(item.status == Consent.DisclosureMappingStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToReady() throws {
        let item = Consent.newDisclosureMapping("code-406", title: "title-881")
        try item.moveTo(Consent.DisclosureMappingStatus.ready)
        #expect(item.status == Consent.DisclosureMappingStatus.ready)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newDisclosureMapping("code-406", title: "title-881")
        item.status = Consent.DisclosureMappingStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureMappingStatus.idle) }
    }
}
