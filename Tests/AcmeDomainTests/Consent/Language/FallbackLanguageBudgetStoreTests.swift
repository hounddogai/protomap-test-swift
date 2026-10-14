@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryFallbackLanguageBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.FallbackLanguageBudgetStore = Consent.newMemoryFallbackLanguageBudgetStore()
        let item = Consent.newFallbackLanguageBudget("code-294", title: "title-691")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
