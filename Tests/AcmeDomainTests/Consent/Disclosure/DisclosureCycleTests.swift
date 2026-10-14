@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureCycleTests {
    @Test func startsInCreated() throws {
        let item = Consent.newDisclosureCycle("code-462", title: "title-706")
        #expect(item.status == Consent.DisclosureCycleStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Consent.newDisclosureCycle("code-462", title: "title-706")
        try item.moveTo(Consent.DisclosureCycleStatus.retired)
        #expect(item.status == Consent.DisclosureCycleStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newDisclosureCycle("code-462", title: "title-706")
        item.status = Consent.DisclosureCycleStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureCycleStatus.created) }
    }
}
