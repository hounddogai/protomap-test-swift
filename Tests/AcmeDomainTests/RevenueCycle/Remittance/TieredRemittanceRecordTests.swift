@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceRecordTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newTieredRemittanceRecord("code-411", name: "name-4")
        #expect(item.status == RevenueCycle.TieredRemittanceRecordStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newTieredRemittanceRecord("code-411", name: "name-4")
        try item.moveTo(RevenueCycle.TieredRemittanceRecordStatus.scheduled)
        #expect(item.status == RevenueCycle.TieredRemittanceRecordStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newTieredRemittanceRecord("code-411", name: "name-4")
        item.status = RevenueCycle.TieredRemittanceRecordStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredRemittanceRecordStatus.planned) }
    }
}
