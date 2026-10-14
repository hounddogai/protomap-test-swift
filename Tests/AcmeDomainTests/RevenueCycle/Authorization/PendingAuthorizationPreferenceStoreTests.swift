@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryPendingAuthorizationPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.PendingAuthorizationPreferenceStore = RevenueCycle.newMemoryPendingAuthorizationPreferenceStore()
        let item = RevenueCycle.newPendingAuthorizationPreference("code-391", label: "label-803")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
