@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureCycleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureCycleStore = Consent.newMemoryDisclosureCycleStore()
        let item = Consent.newDisclosureCycle("code-462", title: "title-706")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
