@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseCycleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultDispenseCycleEngine()
        let item = Pharmacy.newDispenseCycle("code-179", title: "title-530")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
