@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientCredentialCheckpointEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultLenientCredentialCheckpointEngine(Kit.Flags.newRegistry())
        let item = Staffing.newLenientCredentialCheckpoint("code-908", title: "title-953")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
