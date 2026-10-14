@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentMemoryCappedRevocationAdjustmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Consent.CappedRevocationAdjustmentStore = Consent.newMemoryCappedRevocationAdjustmentStore()
        let item = Consent.newCappedRevocationAdjustment("code-626", label: "label-982")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
