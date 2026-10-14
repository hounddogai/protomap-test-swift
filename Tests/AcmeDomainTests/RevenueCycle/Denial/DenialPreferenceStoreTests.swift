@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialPreferenceStore = RevenueCycle.newMemoryDenialPreferenceStore()
        let item = RevenueCycle.newDenialPreference("code-756", title: "title-481")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
