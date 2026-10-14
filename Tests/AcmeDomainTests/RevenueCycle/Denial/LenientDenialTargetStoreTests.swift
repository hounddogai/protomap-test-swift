@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryLenientDenialTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.LenientDenialTargetStore = RevenueCycle.newMemoryLenientDenialTargetStore()
        let item = RevenueCycle.newLenientDenialTarget("code-36", label: "label-581")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
