@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAlertVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AlertVarianceStore = ClinicalOps.newMemoryAlertVarianceStore()
        let item = ClinicalOps.newAlertVariance("code-559", label: "label-591")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
