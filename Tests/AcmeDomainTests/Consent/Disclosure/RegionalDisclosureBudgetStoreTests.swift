@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalDisclosureBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalDisclosureBudgetStore = Consent.newMemoryRegionalDisclosureBudgetStore()
        let item = Consent.newRegionalDisclosureBudget("code-777", title: "title-954")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
