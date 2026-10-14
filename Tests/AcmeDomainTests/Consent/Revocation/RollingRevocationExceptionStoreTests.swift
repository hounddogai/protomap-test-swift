@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingRevocationExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingRevocationExceptionStore = Consent.newMemoryRollingRevocationExceptionStore()
        let item = Consent.newRollingRevocationException("code-368", label: "label-734")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
