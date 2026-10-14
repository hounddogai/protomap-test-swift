@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryChargeScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.ChargeScheduleStore = RevenueCycle.newMemoryChargeScheduleStore()
        let item = RevenueCycle.newChargeSchedule("code-591", name: "name-854")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
