@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSeasonalAccessionAgreementTests {
    @Test func startsInNew() throws {
        let item = Labs.newSeasonalAccessionAgreement("code-457", title: "title-270")
        #expect(item.status == Labs.SeasonalAccessionAgreementStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Labs.newSeasonalAccessionAgreement("code-457", title: "title-270")
        try item.moveTo(Labs.SeasonalAccessionAgreementStatus.running)
        #expect(item.status == Labs.SeasonalAccessionAgreementStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Labs.newSeasonalAccessionAgreement("code-457", title: "title-270")
        item.status = Labs.SeasonalAccessionAgreementStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Labs.SeasonalAccessionAgreementStatus.new) }
    }
}
