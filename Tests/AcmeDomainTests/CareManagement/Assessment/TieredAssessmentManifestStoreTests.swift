@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredAssessmentManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredAssessmentManifestStore = CareManagement.newMemoryTieredAssessmentManifestStore()
        let item = CareManagement.newTieredAssessmentManifest("code-272", title: "title-96")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
