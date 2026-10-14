@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyCycleStore = Consent.newMemoryProxyCycleStore()
        let item = Consent.newProxyCycle("code-109", name: "name-771")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
