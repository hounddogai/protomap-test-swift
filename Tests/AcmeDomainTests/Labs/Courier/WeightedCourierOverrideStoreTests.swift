@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedCourierOverrideStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedCourierOverrideStore = Labs.newMemoryWeightedCourierOverrideStore()
        let item = Labs.newWeightedCourierOverride("code-774", label: "label-786")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
