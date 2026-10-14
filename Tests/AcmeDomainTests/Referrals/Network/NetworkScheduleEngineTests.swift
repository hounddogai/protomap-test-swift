@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkScheduleEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultNetworkScheduleEngine(Kit.Flags.newRegistry())
        let item = Referrals.newNetworkSchedule("code-350", title: "title-499")
        let result = engine.compute(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
