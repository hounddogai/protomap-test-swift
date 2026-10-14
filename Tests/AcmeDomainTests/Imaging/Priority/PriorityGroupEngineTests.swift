@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPriorityGroupEngine()
        let item = Imaging.newPriorityGroup("code-201", label: "label-439")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
