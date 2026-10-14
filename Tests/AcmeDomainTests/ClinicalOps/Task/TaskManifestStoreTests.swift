@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsMemoryTaskManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any ClinicalOps.TaskManifestStore = ClinicalOps.newMemoryTaskManifestStore()
        let item = ClinicalOps.newTaskManifest("code-186", label: "label-140")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
