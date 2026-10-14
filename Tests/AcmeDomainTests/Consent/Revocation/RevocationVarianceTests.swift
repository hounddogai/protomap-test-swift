@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationVarianceTests {
    @Test func startsInCreated() throws {
        let item = Consent.newRevocationVariance("code-225", label: "label-744")
        #expect(item.status == Consent.RevocationVarianceStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToPublished() throws {
        let item = Consent.newRevocationVariance("code-225", label: "label-744")
        try item.moveTo(Consent.RevocationVarianceStatus.published)
        #expect(item.status == Consent.RevocationVarianceStatus.published)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Consent.newRevocationVariance("code-225", label: "label-744")
        item.status = Consent.RevocationVarianceStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Consent.RevocationVarianceStatus.created) }
    }
}
