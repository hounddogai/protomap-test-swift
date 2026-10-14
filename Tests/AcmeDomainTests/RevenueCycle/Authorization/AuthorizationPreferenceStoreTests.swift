@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryAuthorizationPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.AuthorizationPreferenceStore = RevenueCycle.newMemoryAuthorizationPreferenceStore()
        let item = RevenueCycle.newAuthorizationPreference("code-803", label: "label-311")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
