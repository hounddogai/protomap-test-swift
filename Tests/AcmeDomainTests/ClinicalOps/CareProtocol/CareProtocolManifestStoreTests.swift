@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryCareProtocolManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.CareProtocolManifestStore = ClinicalOps.newMemoryCareProtocolManifestStore()
        let item = ClinicalOps.newCareProtocolManifest("code-932", name: "name-626")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
