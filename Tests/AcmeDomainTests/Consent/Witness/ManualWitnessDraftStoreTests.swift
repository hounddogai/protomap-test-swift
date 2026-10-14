@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryManualWitnessDraftStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ManualWitnessDraftStore = Consent.newMemoryManualWitnessDraftStore()
        let item = Consent.newManualWitnessDraft("code-723", title: "title-744")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
