@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRevocationExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RevocationExceptionStore = Consent.newMemoryRevocationExceptionStore()
        let item = Consent.newRevocationException("code-874", name: "name-916")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
