@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialMappingStore = RevenueCycle.newMemoryDenialMappingStore()
        let item = RevenueCycle.newDenialMapping("code-980", label: "label-140")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
