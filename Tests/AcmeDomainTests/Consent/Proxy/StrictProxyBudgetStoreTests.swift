@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryStrictProxyBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.StrictProxyBudgetStore = Consent.newMemoryStrictProxyBudgetStore()
        let item = Consent.newStrictProxyBudget("code-904", title: "title-917")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
