@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledPanelGroupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledPanelGroupStore = Labs.newMemoryScheduledPanelGroupStore()
        let item = Labs.newScheduledPanelGroup("code-533", title: "title-759")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
