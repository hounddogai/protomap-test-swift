@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultCourierLedgerEngine(Kit.Flags.newRegistry())
        let item = Labs.newCourierLedger("code-276", title: "title-633")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
