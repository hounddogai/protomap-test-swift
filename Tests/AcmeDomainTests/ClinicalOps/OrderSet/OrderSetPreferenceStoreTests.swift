@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryOrderSetPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.OrderSetPreferenceStore = ClinicalOps.newMemoryOrderSetPreferenceStore()
        let item = ClinicalOps.newOrderSetPreference("code-16", label: "label-203")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
