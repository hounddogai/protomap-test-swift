@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPrimaryLanguageBatchTests {
    @Test func startsInIdle() throws {
        let item = Consent.newPrimaryLanguageBatch("code-880", name: "name-504")
        #expect(item.status == Consent.PrimaryLanguageBatchStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Consent.newPrimaryLanguageBatch("code-880", name: "name-504")
        try item.moveTo(Consent.PrimaryLanguageBatchStatus.warming)
        #expect(item.status == Consent.PrimaryLanguageBatchStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Consent.newPrimaryLanguageBatch("code-880", name: "name-504")
        item.status = Consent.PrimaryLanguageBatchStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Consent.PrimaryLanguageBatchStatus.idle) }
    }
}
