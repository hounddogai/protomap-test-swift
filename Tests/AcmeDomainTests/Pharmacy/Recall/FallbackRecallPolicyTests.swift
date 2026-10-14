@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackRecallPolicyTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newFallbackRecallPolicy("code-66", label: "label-429")
        #expect(item.status == Pharmacy.FallbackRecallPolicyStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToCancelled() throws {
        let item = Pharmacy.newFallbackRecallPolicy("code-66", label: "label-429")
        try item.moveTo(Pharmacy.FallbackRecallPolicyStatus.cancelled)
        #expect(item.status == Pharmacy.FallbackRecallPolicyStatus.cancelled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newFallbackRecallPolicy("code-66", label: "label-429")
        item.status = Pharmacy.FallbackRecallPolicyStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FallbackRecallPolicyStatus.planned) }
    }
}
