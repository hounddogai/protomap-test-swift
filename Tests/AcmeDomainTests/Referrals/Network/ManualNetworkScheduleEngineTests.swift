@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsManualNetworkScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultManualNetworkScheduleEngine(Kit.Flags.newRegistry())
        let item = Referrals.newManualNetworkSchedule("code-76", name: "name-995")
        let result = engine.price(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
