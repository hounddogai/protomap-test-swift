@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveHandoffVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveHandoffVarianceStore = ClinicalOps.newMemoryAdaptiveHandoffVarianceStore()
        let item = ClinicalOps.newAdaptiveHandoffVariance("code-115", label: "label-680")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
