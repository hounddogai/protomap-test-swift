@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadProfileStore = Imaging.newMemoryReadProfileStore()
        let item = Imaging.newReadProfile("code-895", title: "title-645")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
