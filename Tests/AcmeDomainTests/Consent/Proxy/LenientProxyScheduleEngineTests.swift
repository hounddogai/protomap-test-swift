@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultLenientProxyScheduleEngine(Kit.Flags.newRegistry())
        let item = Consent.newLenientProxySchedule("code-216", name: "name-59")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
