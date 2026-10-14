@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionVarianceTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newInteractionVariance("code-18", title: "title-818")
        #expect(item.status == Pharmacy.InteractionVarianceStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newInteractionVariance("code-18", title: "title-818")
        try item.moveTo(Pharmacy.InteractionVarianceStatus.done)
        #expect(item.status == Pharmacy.InteractionVarianceStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newInteractionVariance("code-18", title: "title-818")
        item.status = Pharmacy.InteractionVarianceStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.InteractionVarianceStatus.new) }
    }
}
