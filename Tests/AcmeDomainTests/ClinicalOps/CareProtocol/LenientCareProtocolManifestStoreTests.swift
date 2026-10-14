@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryLenientCareProtocolManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.LenientCareProtocolManifestStore = ClinicalOps.newMemoryLenientCareProtocolManifestStore()
        let item = ClinicalOps.newLenientCareProtocolManifest("code-183", label: "label-792")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
