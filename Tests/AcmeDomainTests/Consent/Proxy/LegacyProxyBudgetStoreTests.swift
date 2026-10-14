@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLegacyProxyBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LegacyProxyBudgetStore = Consent.newMemoryLegacyProxyBudgetStore()
        let item = Consent.newLegacyProxyBudget("code-822", title: "title-696")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
