@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingProxyOverrideTests {
    @Test func startsInRequested() throws {
        let item = Consent.newRollingProxyOverride("code-137", name: "name-500")
        #expect(item.status == Consent.RollingProxyOverrideStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newRollingProxyOverride("code-137", name: "name-500")
        try item.moveTo(Consent.RollingProxyOverrideStatus.expired)
        #expect(item.status == Consent.RollingProxyOverrideStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newRollingProxyOverride("code-137", name: "name-500")
        item.status = Consent.RollingProxyOverrideStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RollingProxyOverrideStatus.requested) }
    }
}
