@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCappedModalityPolicyStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CappedModalityPolicyStore = Imaging.newMemoryCappedModalityPolicyStore()
        let item = Imaging.newCappedModalityPolicy("code-618", label: "label-354")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
