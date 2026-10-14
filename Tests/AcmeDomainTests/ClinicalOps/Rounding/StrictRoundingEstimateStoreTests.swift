@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryStrictRoundingEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.StrictRoundingEstimateStore = ClinicalOps.newMemoryStrictRoundingEstimateStore()
        let item = ClinicalOps.newStrictRoundingEstimate("code-603", name: "name-965")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
