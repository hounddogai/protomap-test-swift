@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionBaselineTests {
    @Test func startsInCreated() throws {
        let item = Pharmacy.newPrimaryInteractionBaseline("code-203", label: "label-167")
        #expect(item.status == Pharmacy.PrimaryInteractionBaselineStatus.created)
        #expect(!item.isTerminal())
    }

    @Test func movesToRetired() throws {
        let item = Pharmacy.newPrimaryInteractionBaseline("code-203", label: "label-167")
        try item.moveTo(Pharmacy.PrimaryInteractionBaselineStatus.retired)
        #expect(item.status == Pharmacy.PrimaryInteractionBaselineStatus.retired)
    }

    @Test func rejectsMovesFromRetired() throws {
        let item = Pharmacy.newPrimaryInteractionBaseline("code-203", label: "label-167")
        item.status = Pharmacy.PrimaryInteractionBaselineStatus.retired
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryInteractionBaselineStatus.created) }
    }
}
