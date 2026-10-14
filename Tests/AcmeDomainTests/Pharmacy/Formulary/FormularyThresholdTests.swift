@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyThresholdTests {
    @Test func startsInOpen() throws {
        let item = Pharmacy.newFormularyThreshold("code-321", name: "name-26")
        #expect(item.status == Pharmacy.FormularyThresholdStatus.`open`)
        #expect(!item.isTerminal())
    }

    @Test func movesToResolved() throws {
        let item = Pharmacy.newFormularyThreshold("code-321", name: "name-26")
        try item.moveTo(Pharmacy.FormularyThresholdStatus.resolved)
        #expect(item.status == Pharmacy.FormularyThresholdStatus.resolved)
    }

    @Test func rejectsMovesFromArchived() throws {
        let item = Pharmacy.newFormularyThreshold("code-321", name: "name-26")
        item.status = Pharmacy.FormularyThresholdStatus.archived
        #expect(throws: (any Error).self) { try item.moveTo(Pharmacy.FormularyThresholdStatus.`open`) }
    }
}
