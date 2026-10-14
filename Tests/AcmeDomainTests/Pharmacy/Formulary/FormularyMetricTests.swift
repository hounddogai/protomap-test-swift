@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyMetricTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newFormularyMetric("code-615", title: "title-641")
        #expect(item.status == Pharmacy.FormularyMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newFormularyMetric("code-615", title: "title-641")
        try item.moveTo(Pharmacy.FormularyMetricStatus.approved)
        #expect(item.status == Pharmacy.FormularyMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newFormularyMetric("code-615", title: "title-641")
        item.status = Pharmacy.FormularyMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyMetricStatus.proposed) }
    }
}
