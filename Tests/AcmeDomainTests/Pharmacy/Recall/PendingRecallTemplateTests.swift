@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingRecallTemplateTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPendingRecallTemplate("code-13", title: "title-253")
        #expect(item.status == Pharmacy.PendingRecallTemplateStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newPendingRecallTemplate("code-13", title: "title-253")
        try item.moveTo(Pharmacy.PendingRecallTemplateStatus.retired)
        #expect(item.status == Pharmacy.PendingRecallTemplateStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPendingRecallTemplate("code-13", title: "title-253")
        item.status = Pharmacy.PendingRecallTemplateStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PendingRecallTemplateStatus.created) }
    }
}
