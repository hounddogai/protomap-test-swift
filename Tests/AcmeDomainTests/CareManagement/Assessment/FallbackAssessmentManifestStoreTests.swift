@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryFallbackAssessmentManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.FallbackAssessmentManifestStore = CareManagement.newMemoryFallbackAssessmentManifestStore()
        let item = CareManagement.newFallbackAssessmentManifest("code-368", title: "title-496")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
