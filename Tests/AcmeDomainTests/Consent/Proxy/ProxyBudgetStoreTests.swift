@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryProxyBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ProxyBudgetStore = Consent.newMemoryProxyBudgetStore()
        let item = Consent.newProxyBudget("code-336", name: "name-523")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
