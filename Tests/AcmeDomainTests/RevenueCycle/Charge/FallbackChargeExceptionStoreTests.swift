@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackChargeExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackChargeExceptionStore = RevenueCycle.newMemoryFallbackChargeExceptionStore()
        let item = RevenueCycle.newFallbackChargeException("code-989", title: "title-943")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
