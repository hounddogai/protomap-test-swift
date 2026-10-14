@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryRollingConsentFormSlotStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.RollingConsentFormSlotStore = Consent.newMemoryRollingConsentFormSlotStore()
        let item = Consent.newRollingConsentFormSlot("code-716", label: "label-581")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
