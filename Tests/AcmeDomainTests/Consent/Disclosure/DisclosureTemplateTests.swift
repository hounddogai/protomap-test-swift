@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureTemplateTests {
    @Test func startsInProposed() throws {
        let item = Consent.newDisclosureTemplate("code-111", title: "title-813")
        #expect(item.status == Consent.DisclosureTemplateStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToRejected() throws {
        let item = Consent.newDisclosureTemplate("code-111", title: "title-813")
        try item.moveTo(Consent.DisclosureTemplateStatus.rejected)
        #expect(item.status == Consent.DisclosureTemplateStatus.rejected)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Consent.newDisclosureTemplate("code-111", title: "title-813")
        item.status = Consent.DisclosureTemplateStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureTemplateStatus.proposed) }
    }
}
