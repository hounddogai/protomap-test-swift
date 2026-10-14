@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyCycleTests {
    @Test func startsInOpen() throws {
        let item = Consent.newProxyCycle("code-109", name: "name-771")
        #expect(item.status == Consent.ProxyCycleStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newProxyCycle("code-109", name: "name-771")
        try item.moveTo(Consent.ProxyCycleStatus.resolved)
        #expect(item.status == Consent.ProxyCycleStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newProxyCycle("code-109", name: "name-771")
        item.status = Consent.ProxyCycleStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.ProxyCycleStatus.`open`) }
    }
}
