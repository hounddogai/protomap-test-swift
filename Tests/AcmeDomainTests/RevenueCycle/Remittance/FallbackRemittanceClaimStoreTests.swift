@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackRemittanceClaimStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackRemittanceClaimStore = RevenueCycle.newMemoryFallbackRemittanceClaimStore()
        let item = RevenueCycle.newFallbackRemittanceClaim("code-315", label: "label-461")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
