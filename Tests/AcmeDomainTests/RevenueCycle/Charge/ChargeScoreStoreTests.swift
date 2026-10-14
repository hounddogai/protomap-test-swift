@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeScoreStore = RevenueCycle.newMemoryChargeScoreStore()
        let item = RevenueCycle.newChargeScore("code-547", title: "title-153")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
