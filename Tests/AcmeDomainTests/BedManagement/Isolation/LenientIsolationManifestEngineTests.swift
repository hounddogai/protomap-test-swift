@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementLenientIsolationManifestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultLenientIsolationManifestEngine()
        let item = BedManagement.newLenientIsolationManifest("code-429", title: "title-469")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
