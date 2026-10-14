@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryConsentFormAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ConsentFormAllocationStore = Consent.newMemoryConsentFormAllocationStore()
        let item = Consent.newConsentFormAllocation("code-69", title: "title-886")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
