@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictAuthorizationWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictAuthorizationWindowStore = RevenueCycle.newMemoryStrictAuthorizationWindowStore()
        let item = RevenueCycle.newStrictAuthorizationWindow("code-678", title: "title-300")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
