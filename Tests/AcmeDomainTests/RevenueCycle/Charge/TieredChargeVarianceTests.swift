@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeVarianceTests {
    @Test func startsInPlanned() throws {
        let item = RevenueCycle.newTieredChargeVariance("code-960", title: "title-823")
        #expect(item.status == RevenueCycle.TieredChargeVarianceStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToScheduled() throws {
        let item = RevenueCycle.newTieredChargeVariance("code-960", title: "title-823")
        try item.moveTo(RevenueCycle.TieredChargeVarianceStatus.scheduled)
        #expect(item.status == RevenueCycle.TieredChargeVarianceStatus.scheduled)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = RevenueCycle.newTieredChargeVariance("code-960", title: "title-823")
        item.status = RevenueCycle.TieredChargeVarianceStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(RevenueCycle.TieredChargeVarianceStatus.planned) }
    }
}
