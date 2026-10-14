@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeForecastTests {
    @Test func startsInProposed() throws {
        let item = Labs.newManualReferenceRangeForecast("code-101", label: "label-782")
        #expect(item.status == Labs.ManualReferenceRangeForecastStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Labs.newManualReferenceRangeForecast("code-101", label: "label-782")
        try item.moveTo(Labs.ManualReferenceRangeForecastStatus.approved)
        #expect(item.status == Labs.ManualReferenceRangeForecastStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Labs.newManualReferenceRangeForecast("code-101", label: "label-782")
        item.status = Labs.ManualReferenceRangeForecastStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Labs.ManualReferenceRangeForecastStatus.proposed) }
    }
}
