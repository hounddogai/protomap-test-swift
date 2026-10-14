@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementMemoryOutreachPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any CareManagement.OutreachPreferenceStore = CareManagement.newMemoryOutreachPreferenceStore()
        let item = CareManagement.newOutreachPreference("code-925", title: "title-13")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
