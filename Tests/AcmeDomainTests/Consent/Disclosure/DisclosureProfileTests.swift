@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureProfileTests {
    @Test func startsInOpen() throws {
        let item = Consent.newDisclosureProfile("code-831", name: "name-811")
        #expect(item.status == Consent.DisclosureProfileStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToArchived() throws {
        let item = Consent.newDisclosureProfile("code-831", name: "name-811")
        try item.moveTo(Consent.DisclosureProfileStatus.archived)
        #expect(item.status == Consent.DisclosureProfileStatus.archived)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newDisclosureProfile("code-831", name: "name-811")
        item.status = Consent.DisclosureProfileStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.DisclosureProfileStatus.`open`) }
    }
}
