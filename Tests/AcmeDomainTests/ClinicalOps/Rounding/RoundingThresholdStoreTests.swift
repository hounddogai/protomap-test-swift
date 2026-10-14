@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRoundingThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RoundingThresholdStore = ClinicalOps.newMemoryRoundingThresholdStore()
        let item = ClinicalOps.newRoundingThreshold("code-375", name: "name-49")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
