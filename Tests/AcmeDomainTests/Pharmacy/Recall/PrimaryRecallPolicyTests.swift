@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newPrimaryRecallPolicy("code-942", label: "label-779")
        #expect(item.status == Pharmacy.PrimaryRecallPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newPrimaryRecallPolicy("code-942", label: "label-779")
        try item.moveTo(Pharmacy.PrimaryRecallPolicyStatus.inProgress)
        #expect(item.status == Pharmacy.PrimaryRecallPolicyStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newPrimaryRecallPolicy("code-942", label: "label-779")
        item.status = Pharmacy.PrimaryRecallPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.PrimaryRecallPolicyStatus.planned) }
    }
}
