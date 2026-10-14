@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallScoreTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newRecallScore("code-220", label: "label-696")
        #expect(item.status == Pharmacy.RecallScoreStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newRecallScore("code-220", label: "label-696")
        try item.moveTo(Pharmacy.RecallScoreStatus.resolved)
        #expect(item.status == Pharmacy.RecallScoreStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newRecallScore("code-220", label: "label-696")
        item.status = Pharmacy.RecallScoreStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RecallScoreStatus.`open`) }
    }
}
