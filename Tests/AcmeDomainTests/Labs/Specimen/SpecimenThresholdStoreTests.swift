@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenThresholdStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenThresholdStore = Labs.newMemorySpecimenThresholdStore()
        let item = Labs.newSpecimenThreshold("code-970", title: "title-32")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
