@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingOverrideStore = ClinicalOps.newMemoryRoundingOverrideStore()
        let item = ClinicalOps.newRoundingOverride("code-973", label: "label-841")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
