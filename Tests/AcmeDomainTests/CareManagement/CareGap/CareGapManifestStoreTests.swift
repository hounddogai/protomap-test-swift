@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryCareGapManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.CareGapManifestStore = CareManagement.newMemoryCareGapManifestStore()
        let item = CareManagement.newCareGapManifest("code-201", title: "title-287")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
