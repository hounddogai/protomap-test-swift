@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyEstimateTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newFormularyEstimate("code-376", title: "title-731")
        #expect(item.status == Pharmacy.FormularyEstimateStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToStopped() throws {
        let item = Pharmacy.newFormularyEstimate("code-376", title: "title-731")
        try item.moveTo(Pharmacy.FormularyEstimateStatus.stopped)
        #expect(item.status == Pharmacy.FormularyEstimateStatus.stopped)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newFormularyEstimate("code-376", title: "title-731")
        item.status = Pharmacy.FormularyEstimateStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyEstimateStatus.idle) }
    }
}
