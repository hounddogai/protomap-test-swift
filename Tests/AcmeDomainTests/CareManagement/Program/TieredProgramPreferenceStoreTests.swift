@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryTieredProgramPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.TieredProgramPreferenceStore = CareManagement.newMemoryTieredProgramPreferenceStore()
        let item = CareManagement.newTieredProgramPreference("code-129", name: "name-745")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
