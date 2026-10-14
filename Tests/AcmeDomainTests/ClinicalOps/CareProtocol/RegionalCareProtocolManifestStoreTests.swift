@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryRegionalCareProtocolManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.RegionalCareProtocolManifestStore = ClinicalOps.newMemoryRegionalCareProtocolManifestStore()
        let item = ClinicalOps.newRegionalCareProtocolManifest("code-536", label: "label-316")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
