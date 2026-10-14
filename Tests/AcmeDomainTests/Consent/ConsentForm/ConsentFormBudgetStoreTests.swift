@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormBudgetStore = Consent.newMemoryConsentFormBudgetStore()
        let item = Consent.newConsentFormBudget("code-735", name: "name-251")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
