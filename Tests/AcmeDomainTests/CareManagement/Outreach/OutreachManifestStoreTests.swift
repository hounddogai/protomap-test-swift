@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachManifestStore = CareManagement.newMemoryOutreachManifestStore()
        let item = CareManagement.newOutreachManifest("code-474", name: "name-81")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
