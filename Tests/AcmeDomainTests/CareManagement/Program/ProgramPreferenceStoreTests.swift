@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryProgramPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.ProgramPreferenceStore = CareManagement.newMemoryProgramPreferenceStore()
        let item = CareManagement.newProgramPreference("code-149", title: "title-992")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
