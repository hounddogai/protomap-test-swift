@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalRevocationRecordTests {
    @Test func startsInNew() throws {
        let item = Consent.newGlobalRevocationRecord("code-413", title: "title-771")
        #expect(item.status == Consent.GlobalRevocationRecordStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Consent.newGlobalRevocationRecord("code-413", title: "title-771")
        try item.moveTo(Consent.GlobalRevocationRecordStatus.done)
        #expect(item.status == Consent.GlobalRevocationRecordStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Consent.newGlobalRevocationRecord("code-413", title: "title-771")
        item.status = Consent.GlobalRevocationRecordStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Consent.GlobalRevocationRecordStatus.new) }
    }
}
