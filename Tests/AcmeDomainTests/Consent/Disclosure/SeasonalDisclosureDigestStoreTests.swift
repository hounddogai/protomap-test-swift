@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemorySeasonalDisclosureDigestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.SeasonalDisclosureDigestStore = Consent.newMemorySeasonalDisclosureDigestStore()
        let item = Consent.newSeasonalDisclosureDigest("code-874", title: "title-654")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
