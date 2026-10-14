@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskOverrideStore = ClinicalOps.newMemoryTaskOverrideStore()
        let item = ClinicalOps.newTaskOverride("code-802", title: "title-364")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
