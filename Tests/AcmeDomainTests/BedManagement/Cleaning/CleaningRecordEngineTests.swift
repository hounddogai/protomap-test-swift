@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCleaningRecordEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newCleaningRecord("code-859", name: "name-695")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
