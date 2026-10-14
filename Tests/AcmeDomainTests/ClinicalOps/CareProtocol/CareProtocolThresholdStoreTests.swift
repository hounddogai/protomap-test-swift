@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolThresholdStore = ClinicalOps.newMemoryCareProtocolThresholdStore()
        let item = ClinicalOps.newCareProtocolThreshold("code-633", title: "title-816")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
