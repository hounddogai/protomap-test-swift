@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryStrictDenialMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.StrictDenialMappingStore = RevenueCycle.newMemoryStrictDenialMappingStore()
        let item = RevenueCycle.newStrictDenialMapping("code-432", name: "name-28")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
