@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryGlobalReadVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.GlobalReadVarianceStore = Imaging.newMemoryGlobalReadVarianceStore()
        let item = Imaging.newGlobalReadVariance("code-389", label: "label-487")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
