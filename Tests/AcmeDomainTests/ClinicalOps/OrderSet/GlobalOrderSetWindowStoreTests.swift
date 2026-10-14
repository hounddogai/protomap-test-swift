@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryGlobalOrderSetWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.GlobalOrderSetWindowStore = ClinicalOps.newMemoryGlobalOrderSetWindowStore()
        let item = ClinicalOps.newGlobalOrderSetWindow("code-103", name: "name-137")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
