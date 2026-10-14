@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultRevocationWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultRevocationWindowStore = Consent.newMemoryDefaultRevocationWindowStore()
        let item = Consent.newDefaultRevocationWindow("code-327", label: "label-189")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
