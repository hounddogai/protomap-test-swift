@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolEstimateStore = ClinicalOps.newMemoryCareProtocolEstimateStore()
        let item = ClinicalOps.newCareProtocolEstimate("code-635", label: "label-456")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
