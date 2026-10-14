@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryGlobalRevocationRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.GlobalRevocationRollupStore = Consent.newMemoryGlobalRevocationRollupStore()
        let item = Consent.newGlobalRevocationRollup("code-397", label: "label-473")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
