@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRollingPanelPreferenceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RollingPanelPreferenceStore = Labs.newMemoryRollingPanelPreferenceStore()
        let item = Labs.newRollingPanelPreference("code-842", label: "label-603")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
