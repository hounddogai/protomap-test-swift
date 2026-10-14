@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackDisclosureAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackDisclosureAdjustmentStore = Consent.newMemoryFallbackDisclosureAdjustmentStore()
        let item = Consent.newFallbackDisclosureAdjustment("code-586", name: "name-417")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
