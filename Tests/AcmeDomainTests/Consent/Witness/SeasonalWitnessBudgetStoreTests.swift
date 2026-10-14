@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalWitnessBudgetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalWitnessBudgetStore = Consent.newMemorySeasonalWitnessBudgetStore()
        let item = Consent.newSeasonalWitnessBudget("code-379", title: "title-736")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
