@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningExceptionEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultCleaningExceptionEngine()
        let item = BedManagement.newCleaningException("code-943", label: "label-218")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
