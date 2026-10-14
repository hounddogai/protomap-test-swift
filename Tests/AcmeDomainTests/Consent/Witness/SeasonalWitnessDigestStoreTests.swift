@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalWitnessDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalWitnessDigestStore = Consent.newMemorySeasonalWitnessDigestStore()
        let item = Consent.newSeasonalWitnessDigest("code-115", name: "name-380")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
