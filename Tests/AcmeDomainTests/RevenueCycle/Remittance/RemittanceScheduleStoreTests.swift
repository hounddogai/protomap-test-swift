@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryRemittanceScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.RemittanceScheduleStore = RevenueCycle.newMemoryRemittanceScheduleStore()
        let item = RevenueCycle.newRemittanceSchedule("code-615", title: "title-715")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
