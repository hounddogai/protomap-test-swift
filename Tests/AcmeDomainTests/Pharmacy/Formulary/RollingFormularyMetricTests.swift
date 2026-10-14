@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRollingFormularyMetricTests {
    @Test func startsInPlanned() throws {
        let item = Pharmacy.newRollingFormularyMetric("code-180", title: "title-582")
        #expect(item.status == Pharmacy.RollingFormularyMetricStatus.planned)
        #expect(!item.isTerminal())
    }

    @Test func movesToInProgress() throws {
        let item = Pharmacy.newRollingFormularyMetric("code-180", title: "title-582")
        try item.moveTo(Pharmacy.RollingFormularyMetricStatus.inProgress)
        #expect(item.status == Pharmacy.RollingFormularyMetricStatus.inProgress)
    }

    @Test func rejectsMovesFromCancelled() throws {
        let item = Pharmacy.newRollingFormularyMetric("code-180", title: "title-582")
        item.status = Pharmacy.RollingFormularyMetricStatus.cancelled
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.RollingFormularyMetricStatus.planned) }
    }
}
