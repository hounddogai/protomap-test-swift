@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementWeightedProgramWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultWeightedProgramWindowEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newWeightedProgramWindow("code-473", label: "label-159")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
