@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationGroupStore = Consent.newMemoryRevocationGroupStore()
        let item = Consent.newRevocationGroup("code-113", label: "label-846")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
