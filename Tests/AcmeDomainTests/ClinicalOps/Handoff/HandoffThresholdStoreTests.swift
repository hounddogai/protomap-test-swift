@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffThresholdStore = ClinicalOps.newMemoryHandoffThresholdStore()
        let item = ClinicalOps.newHandoffThreshold("code-111", title: "title-904")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
