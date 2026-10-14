@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAdaptiveAccessionBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AdaptiveAccessionBundleStore = Labs.newMemoryAdaptiveAccessionBundleStore()
        let item = Labs.newAdaptiveAccessionBundle("code-106", label: "label-395")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
