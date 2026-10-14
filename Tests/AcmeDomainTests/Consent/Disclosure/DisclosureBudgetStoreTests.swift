@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureBudgetStore = Consent.newMemoryDisclosureBudgetStore()
        let item = Consent.newDisclosureBudget("code-817", title: "title-228")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
