@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryGlobalCourierMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.GlobalCourierMappingStore = Labs.newMemoryGlobalCourierMappingStore()
        let item = Labs.newGlobalCourierMapping("code-978", title: "title-554")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
