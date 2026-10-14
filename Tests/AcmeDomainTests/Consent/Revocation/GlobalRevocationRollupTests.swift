@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationRollupTests {
    @Test func startsInRequested() throws {
        let item = Consent.newGlobalRevocationRollup("code-397", label: "label-473")
        #expect(item.status == Consent.GlobalRevocationRollupStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newGlobalRevocationRollup("code-397", label: "label-473")
        try item.moveTo(Consent.GlobalRevocationRollupStatus.expired)
        #expect(item.status == Consent.GlobalRevocationRollupStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newGlobalRevocationRollup("code-397", label: "label-473")
        item.status = Consent.GlobalRevocationRollupStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalRevocationRollupStatus.requested) }
    }
}
