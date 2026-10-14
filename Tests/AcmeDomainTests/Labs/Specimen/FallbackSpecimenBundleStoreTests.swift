@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackSpecimenBundleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackSpecimenBundleStore = Labs.newMemoryFallbackSpecimenBundleStore()
        let item = Labs.newFallbackSpecimenBundle("code-336", label: "label-436")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
