@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveCareProtocolThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveCareProtocolThresholdStore = Imaging.newMemoryAdaptiveCareProtocolThresholdStore()
        let item = Imaging.newAdaptiveCareProtocolThreshold("code-579", title: "title-782")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
