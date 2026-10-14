@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTransferRecordEngine()
        let item = BedManagement.newTransferRecord("code-703", label: "label-667")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
