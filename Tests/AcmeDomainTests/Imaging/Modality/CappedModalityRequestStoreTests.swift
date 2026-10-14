@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedModalityRequestStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedModalityRequestStore = Imaging.newMemoryCappedModalityRequestStore()
        let item = Imaging.newCappedModalityRequest("code-119", label: "label-197")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
