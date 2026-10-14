@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackTaskEntryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackTaskEntryStore = ClinicalOps.newMemoryFallbackTaskEntryStore()
        let item = ClinicalOps.newFallbackTaskEntry("code-555", title: "title-484")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
