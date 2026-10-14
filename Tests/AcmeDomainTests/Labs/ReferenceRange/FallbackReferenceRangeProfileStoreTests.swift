@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackReferenceRangeProfileStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackReferenceRangeProfileStore = Labs.newMemoryFallbackReferenceRangeProfileStore()
        let item = Labs.newFallbackReferenceRangeProfile("code-45", label: "label-491")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
