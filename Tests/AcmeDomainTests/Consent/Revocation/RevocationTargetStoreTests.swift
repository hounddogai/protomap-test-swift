@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationTargetStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationTargetStore = Consent.newMemoryRevocationTargetStore()
        let item = Consent.newRevocationTarget("code-860", title: "title-482")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
