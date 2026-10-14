@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityRequestStore = Imaging.newMemoryPriorityRequestStore()
        let item = Imaging.newPriorityRequest("code-667", name: "name-65")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
