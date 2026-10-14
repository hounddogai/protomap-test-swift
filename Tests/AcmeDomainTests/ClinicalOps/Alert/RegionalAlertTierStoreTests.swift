@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalAlertTierStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalAlertTierStore = ClinicalOps.newMemoryRegionalAlertTierStore()
        let item = ClinicalOps.newRegionalAlertTier("code-947", label: "label-169")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
