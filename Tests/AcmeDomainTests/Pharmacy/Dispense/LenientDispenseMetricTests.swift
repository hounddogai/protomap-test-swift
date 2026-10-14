@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientDispenseMetricTests {
    @Test func startsInProposed() throws {
        let item = Pharmacy.newLenientDispenseMetric("code-836", name: "name-178")
        #expect(item.status == Pharmacy.LenientDispenseMetricStatus.proposed)
        #expect(!item.isTerminal())
    }

    @Test func movesToApproved() throws {
        let item = Pharmacy.newLenientDispenseMetric("code-836", name: "name-178")
        try item.moveTo(Pharmacy.LenientDispenseMetricStatus.approved)
        #expect(item.status == Pharmacy.LenientDispenseMetricStatus.approved)
    }

    @Test func rejectsMovesFromWithdrawn() throws {
        let item = Pharmacy.newLenientDispenseMetric("code-836", name: "name-178")
        item.status = Pharmacy.LenientDispenseMetricStatus.withdrawn
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.LenientDispenseMetricStatus.proposed) }
    }
}
