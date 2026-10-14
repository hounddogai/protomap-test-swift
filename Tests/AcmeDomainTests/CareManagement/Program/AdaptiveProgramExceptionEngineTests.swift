@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementAdaptiveProgramExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultAdaptiveProgramExceptionEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newAdaptiveProgramException("code-704", title: "title-871")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
