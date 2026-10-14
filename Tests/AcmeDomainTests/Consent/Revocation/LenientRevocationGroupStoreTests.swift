@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLenientRevocationGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LenientRevocationGroupStore = Consent.newMemoryLenientRevocationGroupStore()
        let item = Consent.newLenientRevocationGroup("code-26", name: "name-862")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
