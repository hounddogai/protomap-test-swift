@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDefaultAuthorizationTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DefaultAuthorizationTargetStore = RevenueCycle.newMemoryDefaultAuthorizationTargetStore()
        let item = RevenueCycle.newDefaultAuthorizationTarget("code-81", title: "title-869")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
