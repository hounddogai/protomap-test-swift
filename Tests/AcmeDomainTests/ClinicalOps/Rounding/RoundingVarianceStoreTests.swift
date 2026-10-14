@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingVarianceStore = ClinicalOps.newMemoryRoundingVarianceStore()
        let item = ClinicalOps.newRoundingVariance("code-118", title: "title-27")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
