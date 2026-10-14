@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadRequestStore = Imaging.newMemoryReadRequestStore()
        let item = Imaging.newReadRequest("code-666", name: "name-593")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
