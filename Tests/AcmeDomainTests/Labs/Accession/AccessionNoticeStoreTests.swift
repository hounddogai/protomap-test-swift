@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionNoticeStore = Labs.newMemoryAccessionNoticeStore()
        let item = Labs.newAccessionNotice("code-65", label: "label-572")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
