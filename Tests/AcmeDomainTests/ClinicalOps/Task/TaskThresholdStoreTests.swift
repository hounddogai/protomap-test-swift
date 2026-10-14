@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskThresholdStore = ClinicalOps.newMemoryTaskThresholdStore()
        let item = ClinicalOps.newTaskThreshold("code-692", name: "name-268")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
