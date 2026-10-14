@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedWitnessNoticeTests {
    @Test func startsInOpen() throws {
        let item = Consent.newBatchedWitnessNotice("code-31", label: "label-159")
        #expect(item.status == Consent.BatchedWitnessNoticeStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Consent.newBatchedWitnessNotice("code-31", label: "label-159")
        try item.moveTo(Consent.BatchedWitnessNoticeStatus.resolved)
        #expect(item.status == Consent.BatchedWitnessNoticeStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Consent.newBatchedWitnessNotice("code-31", label: "label-159")
        item.status = Consent.BatchedWitnessNoticeStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Consent.BatchedWitnessNoticeStatus.`open`) }
    }
}
