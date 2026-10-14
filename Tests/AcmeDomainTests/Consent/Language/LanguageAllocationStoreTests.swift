@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryLanguageAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.LanguageAllocationStore = Consent.newMemoryLanguageAllocationStore()
        let item = Consent.newLanguageAllocation("code-397", name: "name-615")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
