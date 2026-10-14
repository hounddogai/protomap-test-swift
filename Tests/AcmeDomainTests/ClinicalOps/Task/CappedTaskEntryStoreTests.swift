@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCappedTaskEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CappedTaskEntryStore = ClinicalOps.newMemoryCappedTaskEntryStore()
        let item = ClinicalOps.newCappedTaskEntry("code-755", name: "name-122")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
