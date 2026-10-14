@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialWindowEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Staffing.defaultFallbackCredentialWindowEngine(Kit.Flags.newRegistry())
        let item = Staffing.newFallbackCredentialWindow("code-205", label: "label-365")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
