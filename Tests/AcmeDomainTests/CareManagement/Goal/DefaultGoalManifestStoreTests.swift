@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryDefaultGoalManifestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.DefaultGoalManifestStore = CareManagement.newMemoryDefaultGoalManifestStore()
        let item = CareManagement.newDefaultGoalManifest("code-40", label: "label-166")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
