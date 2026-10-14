@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffVarianceStore = ClinicalOps.newMemoryHandoffVarianceStore()
        let item = ClinicalOps.newHandoffVariance("code-542", label: "label-792")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
