@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledProgramExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultScheduledProgramExceptionEngine()
        let item = CareManagement.newScheduledProgramException("code-558", label: "label-485")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
