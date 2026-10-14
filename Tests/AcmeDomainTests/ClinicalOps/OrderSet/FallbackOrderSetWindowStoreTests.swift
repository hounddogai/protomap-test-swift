@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackOrderSetWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackOrderSetWindowStore = ClinicalOps.newMemoryFallbackOrderSetWindowStore()
        let item = ClinicalOps.newFallbackOrderSetWindow("code-892", label: "label-414")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
