@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingWitnessDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingWitnessDraftStore = Consent.newMemoryPendingWitnessDraftStore()
        let item = Consent.newPendingWitnessDraft("code-651", name: "name-667")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
