@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceAdjustmentTests {
    @Test func startsInOpen() throws {
        let item = RevenueCycle.newManualRemittanceAdjustment("code-791", name: "name-210")
        #expect(item.status == RevenueCycle.ManualRemittanceAdjustmentStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = RevenueCycle.newManualRemittanceAdjustment("code-791", name: "name-210")
        try item.moveTo(RevenueCycle.ManualRemittanceAdjustmentStatus.resolved)
        #expect(item.status == RevenueCycle.ManualRemittanceAdjustmentStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = RevenueCycle.newManualRemittanceAdjustment("code-791", name: "name-210")
        item.status = RevenueCycle.ManualRemittanceAdjustmentStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.ManualRemittanceAdjustmentStatus.`open`) }
    }
}
