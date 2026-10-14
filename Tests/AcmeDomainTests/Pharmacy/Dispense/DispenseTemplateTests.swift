@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseTemplateTests {
    @Test func startsInDraft() throws {
        let item = Pharmacy.newDispenseTemplate("code-88", name: "name-718")
        #expect(item.status == Pharmacy.DispenseTemplateStatus.draft)
        #expect(!item.isTerminal())
    }

    @Test func movesToActive() throws {
        let item = Pharmacy.newDispenseTemplate("code-88", name: "name-718")
        try item.moveTo(Pharmacy.DispenseTemplateStatus.active)
        #expect(item.status == Pharmacy.DispenseTemplateStatus.active)
    }

    @Test func rejectsMovesFromClosed() throws {
        let item = Pharmacy.newDispenseTemplate("code-88", name: "name-718")
        item.status = Pharmacy.DispenseTemplateStatus.closed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.DispenseTemplateStatus.draft) }
    }
}
