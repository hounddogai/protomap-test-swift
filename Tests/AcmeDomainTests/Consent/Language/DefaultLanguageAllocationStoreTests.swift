@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDefaultLanguageAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DefaultLanguageAllocationStore = Consent.newMemoryDefaultLanguageAllocationStore()
        let item = Consent.newDefaultLanguageAllocation("code-958", name: "name-71")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
