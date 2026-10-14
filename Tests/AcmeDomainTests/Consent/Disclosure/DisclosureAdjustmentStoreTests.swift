@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryDisclosureAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.DisclosureAdjustmentStore = Consent.newMemoryDisclosureAdjustmentStore()
        let item = Consent.newDisclosureAdjustment("code-950", label: "label-110")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
