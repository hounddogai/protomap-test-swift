@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskProfileStore = ClinicalOps.newMemoryTaskProfileStore()
        let item = ClinicalOps.newTaskProfile("code-981", label: "label-805")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
