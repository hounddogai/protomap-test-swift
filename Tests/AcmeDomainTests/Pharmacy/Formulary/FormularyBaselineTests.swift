@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyBaselineTests {
    @Test func startsInIdle() throws {
        let item = Pharmacy.newFormularyBaseline("code-635", title: "title-346")
        #expect(item.status == Pharmacy.FormularyBaselineStatus.idle)
        #expect(!item.isTerminal())
    }

    @Test func movesToWarming() throws {
        let item = Pharmacy.newFormularyBaseline("code-635", title: "title-346")
        try item.moveTo(Pharmacy.FormularyBaselineStatus.warming)
        #expect(item.status == Pharmacy.FormularyBaselineStatus.warming)
    }

    @Test func rejectsMovesFromStopped() throws {
        let item = Pharmacy.newFormularyBaseline("code-635", title: "title-346")
        item.status = Pharmacy.FormularyBaselineStatus.stopped
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyBaselineStatus.idle) }
    }
}
