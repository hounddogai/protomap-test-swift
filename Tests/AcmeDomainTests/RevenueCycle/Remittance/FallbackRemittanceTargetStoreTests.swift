@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackRemittanceTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackRemittanceTargetStore = RevenueCycle.newMemoryFallbackRemittanceTargetStore()
        let item = RevenueCycle.newFallbackRemittanceTarget("code-753", title: "title-87")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
