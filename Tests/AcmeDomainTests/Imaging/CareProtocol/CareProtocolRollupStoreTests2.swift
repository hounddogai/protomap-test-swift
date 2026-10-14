@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolRollupStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolRollupStore = Imaging.newMemoryCareProtocolRollupStore()
        let item = Imaging.newCareProtocolRollup("code-189", name: "name-337")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
