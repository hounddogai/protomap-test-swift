@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationRollupStore = Consent.newMemoryRevocationRollupStore()
        let item = Consent.newRevocationRollup("code-466", label: "label-491")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
