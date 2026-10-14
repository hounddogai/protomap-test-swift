@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryWitnessCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.WitnessCycleStore = Consent.newMemoryWitnessCycleStore()
        let item = Consent.newWitnessCycle("code-815", name: "name-125")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
