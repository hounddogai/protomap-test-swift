@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalWitnessOverrideTests {
    @Test func startsInRequested() throws {
        let item = Consent.newGlobalWitnessOverride("code-120", label: "label-457")
        #expect(item.status == Consent.GlobalWitnessOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newGlobalWitnessOverride("code-120", label: "label-457")
        try item.moveTo(Consent.GlobalWitnessOverrideStatus.expired)
        #expect(item.status == Consent.GlobalWitnessOverrideStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newGlobalWitnessOverride("code-120", label: "label-457")
        item.status = Consent.GlobalWitnessOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalWitnessOverrideStatus.requested) }
    }
}
