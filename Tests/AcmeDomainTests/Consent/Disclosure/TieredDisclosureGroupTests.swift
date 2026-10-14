@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentTieredDisclosureGroupTests {
    @Test func startsInProposed() throws {
        let item = Consent.newTieredDisclosureGroup("code-952", name: "name-625")
        #expect(item.status == Consent.TieredDisclosureGroupStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newTieredDisclosureGroup("code-952", name: "name-625")
        try item.moveTo(Consent.TieredDisclosureGroupStatus.rejected)
        #expect(item.status == Consent.TieredDisclosureGroupStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newTieredDisclosureGroup("code-952", name: "name-625")
        item.status = Consent.TieredDisclosureGroupStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.TieredDisclosureGroupStatus.proposed) }
    }
}
