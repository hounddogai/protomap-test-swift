@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictFormularyBaselineTests {
    @Test func startsInNew() throws {
        let item = Pharmacy.newStrictFormularyBaseline("code-105", title: "title-471")
        #expect(item.status == Pharmacy.StrictFormularyBaselineStatus.new)
        #expect(!item.isTerminal())
    }

    @Test func movesToRunning() throws {
        let item = Pharmacy.newStrictFormularyBaseline("code-105", title: "title-471")
        try item.moveTo(Pharmacy.StrictFormularyBaselineStatus.running)
        #expect(item.status == Pharmacy.StrictFormularyBaselineStatus.running)
    }

    @Test func rejectsMovesFromFailed() throws {
        let item = Pharmacy.newStrictFormularyBaseline("code-105", title: "title-471")
        item.status = Pharmacy.StrictFormularyBaselineStatus.failed
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.StrictFormularyBaselineStatus.new) }
    }
}
