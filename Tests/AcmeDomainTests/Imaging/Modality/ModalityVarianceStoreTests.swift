@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalityVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalityVarianceStore = Imaging.newMemoryModalityVarianceStore()
        let item = Imaging.newModalityVariance("code-987", label: "label-414")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
