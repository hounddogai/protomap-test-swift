@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryDenialDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.DenialDraftStore = RevenueCycle.newMemoryDenialDraftStore()
        let item = RevenueCycle.newDenialDraft("code-179", label: "label-406")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
