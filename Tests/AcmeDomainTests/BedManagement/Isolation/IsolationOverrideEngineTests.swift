@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationOverrideEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultIsolationOverrideEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newIsolationOverride("code-545", title: "title-209")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
