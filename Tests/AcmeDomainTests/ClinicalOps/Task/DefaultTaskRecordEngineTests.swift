@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsDefaultTaskRecordEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = ClinicalOps.defaultDefaultTaskRecordEngine(Kit.Flags.newRegistry())
        let item = ClinicalOps.newDefaultTaskRecord("code-615", label: "label-405")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
