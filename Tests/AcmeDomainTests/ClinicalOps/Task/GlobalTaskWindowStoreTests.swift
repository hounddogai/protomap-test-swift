@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalTaskWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalTaskWindowStore = ClinicalOps.newMemoryGlobalTaskWindowStore()
        let item = ClinicalOps.newGlobalTaskWindow("code-68", name: "name-681")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
