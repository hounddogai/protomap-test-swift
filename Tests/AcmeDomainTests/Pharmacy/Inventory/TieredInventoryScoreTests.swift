@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInventoryScoreTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newTieredInventoryScore("code-415", title: "title-729")
        #expect(item.status == Pharmacy.TieredInventoryScoreStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newTieredInventoryScore("code-415", title: "title-729")
        try item.moveTo(Pharmacy.TieredInventoryScoreStatus.running)
        #expect(item.status == Pharmacy.TieredInventoryScoreStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newTieredInventoryScore("code-415", title: "title-729")
        item.status = Pharmacy.TieredInventoryScoreStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.TieredInventoryScoreStatus.new) }
    }
}
