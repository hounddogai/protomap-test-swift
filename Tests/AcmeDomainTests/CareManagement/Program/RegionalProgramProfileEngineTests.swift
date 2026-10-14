@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalProgramProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultRegionalProgramProfileEngine()
        let item = CareManagement.newRegionalProgramProfile("code-625", name: "name-525")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
