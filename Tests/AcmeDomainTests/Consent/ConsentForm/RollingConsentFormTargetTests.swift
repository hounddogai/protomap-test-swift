@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormTargetTests {
    @Test func startsInOpen() throws {
        let item = Consent.newRollingConsentFormTarget("code-869", name: "name-502")
        #expect(item.status == Consent.RollingConsentFormTargetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newRollingConsentFormTarget("code-869", name: "name-502")
        try item.moveTo(Consent.RollingConsentFormTargetStatus.archived)
        #expect(item.status == Consent.RollingConsentFormTargetStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newRollingConsentFormTarget("code-869", name: "name-502")
        item.status = Consent.RollingConsentFormTargetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingConsentFormTargetStatus.`open`) }
    }
}
