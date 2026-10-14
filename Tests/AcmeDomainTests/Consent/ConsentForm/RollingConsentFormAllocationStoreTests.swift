@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingConsentFormAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingConsentFormAllocationStore = Consent.newMemoryRollingConsentFormAllocationStore()
        let item = Consent.newRollingConsentFormAllocation("code-558", label: "label-341")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
