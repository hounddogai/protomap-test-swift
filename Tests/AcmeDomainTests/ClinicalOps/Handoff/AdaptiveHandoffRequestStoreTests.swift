@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryAdaptiveHandoffRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.AdaptiveHandoffRequestStore = ClinicalOps.newMemoryAdaptiveHandoffRequestStore()
        let item = ClinicalOps.newAdaptiveHandoffRequest("code-960", label: "label-904")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
