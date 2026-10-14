@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedModalityWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedModalityWindowStore = Imaging.newMemoryCappedModalityWindowStore()
        let item = Imaging.newCappedModalityWindow("code-335", name: "name-293")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
