@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingDefaultPriorityAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultDefaultPriorityAgreementEngine(Kit.Flags.newRegistry())
        let item = Imaging.newDefaultPriorityAgreement("code-558", label: "label-245")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
