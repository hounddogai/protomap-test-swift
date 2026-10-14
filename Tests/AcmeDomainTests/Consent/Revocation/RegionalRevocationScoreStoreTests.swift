@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRegionalRevocationScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RegionalRevocationScoreStore = Consent.newMemoryRegionalRevocationScoreStore()
        let item = Consent.newRegionalRevocationScore("code-553", label: "label-414")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
