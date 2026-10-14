@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierExceptionEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierException("code-137", title: "title-437")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
