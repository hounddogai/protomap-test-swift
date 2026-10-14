@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryHandoffGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.HandoffGroupStore = ClinicalOps.newMemoryHandoffGroupStore()
        let item = ClinicalOps.newHandoffGroup("code-719", title: "title-893")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
