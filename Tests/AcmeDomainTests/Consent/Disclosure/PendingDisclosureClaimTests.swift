@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingDisclosureClaimTests {
    @Test func startsInRequested() throws {
        let item = Consent.newPendingDisclosureClaim("code-915", name: "name-850")
        #expect(item.status == Consent.PendingDisclosureClaimStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToExpired() throws {
        let item = Consent.newPendingDisclosureClaim("code-915", name: "name-850")
        try item.moveTo(Consent.PendingDisclosureClaimStatus.expired)
        #expect(item.status == Consent.PendingDisclosureClaimStatus.expired)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Consent.newPendingDisclosureClaim("code-915", name: "name-850")
        item.status = Consent.PendingDisclosureClaimStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PendingDisclosureClaimStatus.requested) }
    }
}
