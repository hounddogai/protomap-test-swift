@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientCareGapAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultLenientCareGapAllocationEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newLenientCareGapAllocation("code-86", title: "title-467")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
