@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionTemplateTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newPrimaryInteractionTemplate("code-216", label: "label-680")
        #expect(item.status == Pharmacy.PrimaryInteractionTemplateStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newPrimaryInteractionTemplate("code-216", label: "label-680")
        try item.moveTo(Pharmacy.PrimaryInteractionTemplateStatus.done)
        #expect(item.status == Pharmacy.PrimaryInteractionTemplateStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newPrimaryInteractionTemplate("code-216", label: "label-680")
        item.status = Pharmacy.PrimaryInteractionTemplateStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryInteractionTemplateStatus.new) }
    }
}
