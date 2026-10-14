@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsDefaultSpecimenQuotaEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultDefaultSpecimenQuotaEngine(Kit.Flags.newRegistry())
        let item = Labs.newDefaultSpecimenQuota("code-126", label: "label-174")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
