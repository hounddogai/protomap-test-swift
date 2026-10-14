@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionMappingStore = Labs.newMemoryAccessionMappingStore()
        let item = Labs.newAccessionMapping("code-774", title: "title-972")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
