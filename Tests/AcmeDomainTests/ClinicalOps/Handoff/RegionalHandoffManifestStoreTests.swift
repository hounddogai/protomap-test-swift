@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalHandoffManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalHandoffManifestStore = ClinicalOps.newMemoryRegionalHandoffManifestStore()
        let item = ClinicalOps.newRegionalHandoffManifest("code-806", label: "label-190")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
