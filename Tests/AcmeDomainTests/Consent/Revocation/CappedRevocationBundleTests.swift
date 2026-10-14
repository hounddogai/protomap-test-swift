@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedRevocationBundleTests {
    @Test func startsInProposed() throws {
        let item = Consent.newCappedRevocationBundle("code-296", name: "name-625")
        #expect(item.status == Consent.CappedRevocationBundleStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Consent.newCappedRevocationBundle("code-296", name: "name-625")
        try item.moveTo(Consent.CappedRevocationBundleStatus.approved)
        #expect(item.status == Consent.CappedRevocationBundleStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newCappedRevocationBundle("code-296", name: "name-625")
        item.status = Consent.CappedRevocationBundleStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.CappedRevocationBundleStatus.proposed) }
    }
}
