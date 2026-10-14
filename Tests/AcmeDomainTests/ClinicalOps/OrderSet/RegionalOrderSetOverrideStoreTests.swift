@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalOrderSetOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalOrderSetOverrideStore = ClinicalOps.newMemoryRegionalOrderSetOverrideStore()
        let item = ClinicalOps.newRegionalOrderSetOverride("code-920", label: "label-308")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
