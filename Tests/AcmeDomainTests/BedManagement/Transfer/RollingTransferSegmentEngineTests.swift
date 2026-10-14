@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementRollingTransferSegmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultRollingTransferSegmentEngine(Kit.Flags.newRegistry())
        let item = BedManagement.newRollingTransferSegment("code-857", name: "name-841")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
