@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedFormularyAuditEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultBatchedFormularyAuditEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newBatchedFormularyAudit("code-25", label: "label-932")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
