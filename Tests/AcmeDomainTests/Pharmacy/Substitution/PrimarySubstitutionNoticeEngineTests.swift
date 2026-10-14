@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionNoticeEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultPrimarySubstitutionNoticeEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newPrimarySubstitutionNotice("code-769", label: "label-42")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
