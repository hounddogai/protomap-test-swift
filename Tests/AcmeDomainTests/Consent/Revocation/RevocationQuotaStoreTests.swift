@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationQuotaStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationQuotaStore = Consent.newMemoryRevocationQuotaStore()
        let item = Consent.newRevocationQuota("code-429", label: "label-796")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
