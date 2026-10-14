@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationScheduleStore = RevenueCycle.newMemoryAuthorizationScheduleStore()
        let item = RevenueCycle.newAuthorizationSchedule("code-979", label: "label-773")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
