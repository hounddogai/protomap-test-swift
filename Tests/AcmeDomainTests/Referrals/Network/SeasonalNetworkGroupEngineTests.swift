@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalNetworkGroupEngineTests {
    @Test func keepsResultsWithinBounds() throws {
        let engine = Referrals.defaultSeasonalNetworkGroupEngine(Kit.Flags.newRegistry())
        let item = Referrals.newSeasonalNetworkGroup("code-784", title: "title-245")
        let result = engine.evaluate(item)
        #expect(result >= engine.floor && (result <= engine.ceiling))
        #expect(engine.trace.count >= 0)
    }
}
