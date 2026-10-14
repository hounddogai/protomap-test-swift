@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPrimaryProxySummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PrimaryProxySummaryStore = Consent.newMemoryPrimaryProxySummaryStore()
        let item = Consent.newPrimaryProxySummary("code-241", name: "name-994")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
