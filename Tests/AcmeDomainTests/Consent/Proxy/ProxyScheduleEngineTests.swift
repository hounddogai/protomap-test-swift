@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentProxyScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultProxyScheduleEngine(Kit.Flags.newRegistry())
        let item = Consent.newProxySchedule("code-94", title: "title-79")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
