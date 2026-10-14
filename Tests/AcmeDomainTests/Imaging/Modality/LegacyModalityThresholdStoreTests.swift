@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLegacyModalityThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LegacyModalityThresholdStore = Imaging.newMemoryLegacyModalityThresholdStore()
        let item = Imaging.newLegacyModalityThreshold("code-84", name: "name-656")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
