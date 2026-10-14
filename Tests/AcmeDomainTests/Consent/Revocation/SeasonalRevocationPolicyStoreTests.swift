@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalRevocationPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalRevocationPolicyStore = Consent.newMemorySeasonalRevocationPolicyStore()
        let item = Consent.newSeasonalRevocationPolicy("code-761", name: "name-126")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
