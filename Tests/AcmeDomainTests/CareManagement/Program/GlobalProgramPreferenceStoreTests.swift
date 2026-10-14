@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryGlobalProgramPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.GlobalProgramPreferenceStore = CareManagement.newMemoryGlobalProgramPreferenceStore()
        let item = CareManagement.newGlobalProgramPreference("code-974", title: "title-34")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
