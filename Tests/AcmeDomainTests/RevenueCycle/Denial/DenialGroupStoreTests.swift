@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialGroupStore = RevenueCycle.newMemoryDenialGroupStore()
        let item = RevenueCycle.newDenialGroup("code-862", title: "title-252")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
