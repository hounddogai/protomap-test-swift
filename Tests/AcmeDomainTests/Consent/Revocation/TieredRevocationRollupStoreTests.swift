@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryTieredRevocationRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.TieredRevocationRollupStore = Consent.newMemoryTieredRevocationRollupStore()
        let item = Consent.newTieredRevocationRollup("code-239", label: "label-309")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
