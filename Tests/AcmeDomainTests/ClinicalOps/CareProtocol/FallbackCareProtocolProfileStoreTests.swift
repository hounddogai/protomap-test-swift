@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackCareProtocolProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackCareProtocolProfileStore = ClinicalOps.newMemoryFallbackCareProtocolProfileStore()
        let item = ClinicalOps.newFallbackCareProtocolProfile("code-684", name: "name-337")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
