@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadWindowStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadWindowStore = Imaging.newMemoryReadWindowStore()
        let item = Imaging.newReadWindow("code-975", label: "label-625")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
