@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCappedOrderSetProfileEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultCappedOrderSetProfileEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newCappedOrderSetProfile("code-541", title: "title-250")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
