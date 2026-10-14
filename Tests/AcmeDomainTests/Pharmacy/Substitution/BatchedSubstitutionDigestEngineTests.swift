@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionDigestEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Pharmacy.defaultBatchedSubstitutionDigestEngine(Kit.Flags.newRegistry())
        let item = Pharmacy.newBatchedSubstitutionDigest("code-767", title: "title-738")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
