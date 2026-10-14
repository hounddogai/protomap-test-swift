@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialBaselineStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialBaselineStore = RevenueCycle.newMemoryDenialBaselineStore()
        let item = RevenueCycle.newDenialBaseline("code-335", label: "label-994")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
