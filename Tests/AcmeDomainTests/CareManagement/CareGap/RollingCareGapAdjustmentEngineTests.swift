@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingCareGapAdjustmentEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRollingCareGapAdjustmentEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newRollingCareGapAdjustment("code-194", label: "label-186")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
