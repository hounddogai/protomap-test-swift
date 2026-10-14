@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryPrimaryOrderSetVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.PrimaryOrderSetVarianceStore = ClinicalOps.newMemoryPrimaryOrderSetVarianceStore()
        let item = ClinicalOps.newPrimaryOrderSetVariance("code-328", name: "name-638")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
