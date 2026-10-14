@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackWitnessDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackWitnessDraftStore = Consent.newMemoryFallbackWitnessDraftStore()
        let item = Consent.newFallbackWitnessDraft("code-932", title: "title-518")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
