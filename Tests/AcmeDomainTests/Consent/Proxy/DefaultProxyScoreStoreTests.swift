@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultProxyScoreStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultProxyScoreStore = Consent.newMemoryDefaultProxyScoreStore()
        let item = Consent.newDefaultProxyScore("code-353", label: "label-203")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
