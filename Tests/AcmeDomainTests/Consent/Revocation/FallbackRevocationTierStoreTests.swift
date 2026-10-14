@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackRevocationTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackRevocationTierStore = Consent.newMemoryFallbackRevocationTierStore()
        let item = Consent.newFallbackRevocationTier("code-249", label: "label-769")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
