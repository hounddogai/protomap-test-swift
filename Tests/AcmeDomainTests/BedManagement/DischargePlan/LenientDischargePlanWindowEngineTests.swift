@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientDischargePlanWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLenientDischargePlanWindowEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newLenientDischargePlanWindow("code-292", name: "name-61")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
