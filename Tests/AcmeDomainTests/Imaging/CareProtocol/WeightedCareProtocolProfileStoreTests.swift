@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryWeightedCareProtocolProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.WeightedCareProtocolProfileStore = Imaging.newMemoryWeightedCareProtocolProfileStore()
        let item = Imaging.newWeightedCareProtocolProfile("code-454", title: "title-536")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
