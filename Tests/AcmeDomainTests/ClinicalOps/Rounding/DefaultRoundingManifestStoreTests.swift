@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryDefaultRoundingManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.DefaultRoundingManifestStore = ClinicalOps.newMemoryDefaultRoundingManifestStore()
        let item = ClinicalOps.newDefaultRoundingManifest("code-959", name: "name-841")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
