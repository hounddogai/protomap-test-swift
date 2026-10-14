@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedReadProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedReadProfileStore = Imaging.newMemoryWeightedReadProfileStore()
        let item = Imaging.newWeightedReadProfile("code-709", name: "name-535")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
