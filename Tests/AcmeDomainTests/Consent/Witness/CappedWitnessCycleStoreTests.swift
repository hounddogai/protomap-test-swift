@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedWitnessCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedWitnessCycleStore = Consent.newMemoryCappedWitnessCycleStore()
        let item = Consent.newCappedWitnessCycle("code-697", title: "title-74")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
