@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleMemoryFallbackClaimDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any RevenueCycle.FallbackClaimDraftStore = RevenueCycle.newMemoryFallbackClaimDraftStore()
        let item = RevenueCycle.newFallbackClaimDraft("code-666", title: "title-40")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
