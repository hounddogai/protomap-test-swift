@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalLanguageRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalLanguageRequestStore = Consent.newMemorySeasonalLanguageRequestStore()
        let item = Consent.newSeasonalLanguageRequest("code-28", name: "name-248")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
