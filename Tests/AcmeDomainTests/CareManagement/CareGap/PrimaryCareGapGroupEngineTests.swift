@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPrimaryCareGapGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = CareManagement.defaultPrimaryCareGapGroupEngine(Kit.Flags.newRegistry())
        let item = CareManagement.newPrimaryCareGapGroup("code-638", label: "label-609")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
