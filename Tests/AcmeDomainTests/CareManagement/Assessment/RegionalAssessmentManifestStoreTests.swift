@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryRegionalAssessmentManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.RegionalAssessmentManifestStore = CareManagement.newMemoryRegionalAssessmentManifestStore()
        let item = CareManagement.newRegionalAssessmentManifest("code-198", label: "label-605")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
