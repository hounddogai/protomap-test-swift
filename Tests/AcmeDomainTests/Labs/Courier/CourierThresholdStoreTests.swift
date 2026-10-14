@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryCourierThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.CourierThresholdStore = Labs.newMemoryCourierThresholdStore()
        let item = Labs.newCourierThreshold("code-849", name: "name-859")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
