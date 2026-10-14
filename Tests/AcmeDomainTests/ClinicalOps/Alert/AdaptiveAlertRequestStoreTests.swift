@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveAlertRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveAlertRequestStore = ClinicalOps.newMemoryAdaptiveAlertRequestStore()
        let item = ClinicalOps.newAdaptiveAlertRequest("code-976", title: "title-972")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
