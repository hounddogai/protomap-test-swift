@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationExceptionTests {
    @Test func startsInOpen() throws {
        let item = Consent.newAdaptiveRevocationException("code-979", name: "name-115")
        #expect(item.status == Consent.AdaptiveRevocationExceptionStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newAdaptiveRevocationException("code-979", name: "name-115")
        try item.moveTo(Consent.AdaptiveRevocationExceptionStatus.archived)
        #expect(item.status == Consent.AdaptiveRevocationExceptionStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newAdaptiveRevocationException("code-979", name: "name-115")
        item.status = Consent.AdaptiveRevocationExceptionStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.AdaptiveRevocationExceptionStatus.`open`) }
    }
}
