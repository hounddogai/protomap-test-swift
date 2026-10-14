@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryScheduledConsentFormAllocationStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.ScheduledConsentFormAllocationStore = Consent.newMemoryScheduledConsentFormAllocationStore()
        let item = Consent.newScheduledConsentFormAllocation("code-945", label: "label-165")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
