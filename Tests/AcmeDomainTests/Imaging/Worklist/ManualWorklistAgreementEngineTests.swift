@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualWorklistAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultManualWorklistAgreementEngine(Kit.Flags.newRegistry())
        let item = Imaging.newManualWorklistAgreement("code-749", title: "title-665")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
