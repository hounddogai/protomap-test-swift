@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientCareProtocolThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientCareProtocolThresholdStore = ClinicalOps.newMemoryLenientCareProtocolThresholdStore()
        let item = ClinicalOps.newLenientCareProtocolThreshold("code-771", name: "name-236")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
