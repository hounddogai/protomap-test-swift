@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierMappingStore = Labs.newMemoryCourierMappingStore()
        let item = Labs.newCourierMapping("code-848", name: "name-653")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
