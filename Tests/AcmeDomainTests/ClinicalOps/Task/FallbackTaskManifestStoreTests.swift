@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryFallbackTaskManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.FallbackTaskManifestStore = ClinicalOps.newMemoryFallbackTaskManifestStore()
        let item = ClinicalOps.newFallbackTaskManifest("code-655", name: "name-975")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
