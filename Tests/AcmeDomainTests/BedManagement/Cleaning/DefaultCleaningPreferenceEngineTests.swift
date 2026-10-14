@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDefaultCleaningPreferenceEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = BedManagement.defaultDefaultCleaningPreferenceEngine()
        let item = BedManagement.newDefaultCleaningPreference("code-198", title: "title-593")
        let result = engine.run(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
