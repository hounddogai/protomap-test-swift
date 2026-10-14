@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackAccessionThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackAccessionThresholdStore = Labs.newMemoryFallbackAccessionThresholdStore()
        let item = Labs.newFallbackAccessionThreshold("code-632", name: "name-839")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
