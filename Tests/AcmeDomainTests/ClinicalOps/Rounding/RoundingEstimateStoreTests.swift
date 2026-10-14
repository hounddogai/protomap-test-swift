@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingEstimateStore = ClinicalOps.newMemoryRoundingEstimateStore()
        let item = ClinicalOps.newRoundingEstimate("code-902", name: "name-420")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
