@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultIsolationWindowEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newIsolationWindow("code-701", label: "label-685")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
