@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalFormularyBaselineTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newGlobalFormularyBaseline("code-38", label: "label-399")
        #expect(item.status == Pharmacy.GlobalFormularyBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToDone() throws {
        let item = Pharmacy.newGlobalFormularyBaseline("code-38", label: "label-399")
        try item.moveTo(Pharmacy.GlobalFormularyBaselineStatus.done)
        #expect(item.status == Pharmacy.GlobalFormularyBaselineStatus.done)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newGlobalFormularyBaseline("code-38", label: "label-399")
        item.status = Pharmacy.GlobalFormularyBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.GlobalFormularyBaselineStatus.new) }
    }
}
