@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrimaryReadAgreementEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Imaging.defaultPrimaryReadAgreementEngine(Kit.Flags.newRegistry())
        let item = Imaging.newPrimaryReadAgreement("code-762", name: "name-633")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
