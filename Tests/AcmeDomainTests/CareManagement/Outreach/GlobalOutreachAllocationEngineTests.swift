@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalOutreachAllocationEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultGlobalOutreachAllocationEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newGlobalOutreachAllocation("code-308", label: "label-705")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
