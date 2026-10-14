@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryCappedDenialTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.CappedDenialTargetStore = RevenueCycle.newMemoryCappedDenialTargetStore()
        let item = RevenueCycle.newCappedDenialTarget("code-840", name: "name-43")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
