@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientProxyBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientProxyBudgetStore = Consent.newMemoryLenientProxyBudgetStore()
        let item = Consent.newLenientProxyBudget("code-778", label: "label-438")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
