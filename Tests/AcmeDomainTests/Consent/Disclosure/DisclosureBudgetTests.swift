@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureBudgetTests {
    @Test func startsInOpen() throws {
        let item = Consent.newDisclosureBudget("code-817", title: "title-228")
        #expect(item.status == Consent.DisclosureBudgetStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToInReview() throws {
        let item = Consent.newDisclosureBudget("code-817", title: "title-228")
        try item.moveTo(Consent.DisclosureBudgetStatus.inReview)
        #expect(item.status == Consent.DisclosureBudgetStatus.inReview)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newDisclosureBudget("code-817", title: "title-228")
        item.status = Consent.DisclosureBudgetStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureBudgetStatus.`open`) }
    }
}
