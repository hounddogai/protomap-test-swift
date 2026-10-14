@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryScheduledAccessionNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ScheduledAccessionNoticeStore = Labs.newMemoryScheduledAccessionNoticeStore()
        let item = Labs.newScheduledAccessionNotice("code-753", label: "label-608")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
