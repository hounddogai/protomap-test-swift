@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryPendingConsentFormAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.PendingConsentFormAllocationStore = Consent.newMemoryPendingConsentFormAllocationStore()
        let item = Consent.newPendingConsentFormAllocation("code-274", name: "name-626")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
