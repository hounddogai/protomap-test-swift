@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenNoticeStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenNoticeStore = Labs.newMemorySpecimenNoticeStore()
        let item = Labs.newSpecimenNotice("code-576", label: "label-322")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
