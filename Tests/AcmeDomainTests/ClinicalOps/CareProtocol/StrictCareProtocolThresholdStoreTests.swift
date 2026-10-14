@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictCareProtocolThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictCareProtocolThresholdStore = ClinicalOps.newMemoryStrictCareProtocolThresholdStore()
        let item = ClinicalOps.newStrictCareProtocolThreshold("code-274", name: "name-193")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
