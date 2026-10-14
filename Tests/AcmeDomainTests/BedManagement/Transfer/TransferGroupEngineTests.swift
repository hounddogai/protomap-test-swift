@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementTransferGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultTransferGroupEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newTransferGroup("code-703", name: "name-207")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
