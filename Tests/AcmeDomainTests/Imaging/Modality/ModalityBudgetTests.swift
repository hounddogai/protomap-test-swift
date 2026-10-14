@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingModalityBudgetTests {
    @Test func startsInRequested() throws {
        let item = Imaging.newModalityBudget("code-798", label: "label-300")
        #expect(item.status == Imaging.ModalityBudgetStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = Imaging.newModalityBudget("code-798", label: "label-300")
        try item.moveTo(Imaging.ModalityBudgetStatus.revoked)
        #expect(item.status == Imaging.ModalityBudgetStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = Imaging.newModalityBudget("code-798", label: "label-300")
        item.status = Imaging.ModalityBudgetStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(Imaging.ModalityBudgetStatus.requested) }
    }
}
