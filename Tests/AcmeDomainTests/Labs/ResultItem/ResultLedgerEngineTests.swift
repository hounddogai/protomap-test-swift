@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultLedgerEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Labs.defaultResultLedgerEngine(Kit.Flags.newRegistry())
        let item = Labs.newResultLedger("code-7", name: "name-119")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
