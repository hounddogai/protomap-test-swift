@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedRevocationBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedRevocationBundleStore = Consent.newMemoryCappedRevocationBundleStore()
        let item = Consent.newCappedRevocationBundle("code-296", name: "name-625")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
