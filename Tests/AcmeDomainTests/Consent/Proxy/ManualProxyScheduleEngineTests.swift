@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualProxyScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Consent.defaultManualProxyScheduleEngine()
        let item = Consent.newManualProxySchedule("code-771", title: "title-115")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
