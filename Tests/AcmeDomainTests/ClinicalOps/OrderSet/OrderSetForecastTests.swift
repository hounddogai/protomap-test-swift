@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetForecastTests {
    @Test func startsInRequested() throws {
        let item = ClinicalOps.newOrderSetForecast("code-405", label: "label-213")
        #expect(item.status == ClinicalOps.OrderSetForecastStatus.requested)
        #expect(!item.isTerminal())
    }

    @Test func movesToRevoked() throws {
        let item = ClinicalOps.newOrderSetForecast("code-405", label: "label-213")
        try item.moveTo(ClinicalOps.OrderSetForecastStatus.revoked)
        #expect(item.status == ClinicalOps.OrderSetForecastStatus.revoked)
    }

    @Test func rejectsMovesFromExpired() throws {
        let item = ClinicalOps.newOrderSetForecast("code-405", label: "label-213")
        item.status = ClinicalOps.OrderSetForecastStatus.expired
        #expect(throws: (any Error).self) { try item.moveTo(ClinicalOps.OrderSetForecastStatus.requested) }
    }
}
