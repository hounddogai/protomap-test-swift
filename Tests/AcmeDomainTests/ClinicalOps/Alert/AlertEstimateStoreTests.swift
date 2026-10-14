@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertEstimateStore = ClinicalOps.newMemoryAlertEstimateStore()
        let item = ClinicalOps.newAlertEstimate("code-108", label: "label-617")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
