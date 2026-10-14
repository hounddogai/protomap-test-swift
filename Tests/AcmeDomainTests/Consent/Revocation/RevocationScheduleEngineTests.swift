@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultRevocationScheduleEngine(Kit.Flags.newRegistry())
        let item = Consent.newRevocationSchedule("code-947", name: "name-200")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
