@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySpecimenEstimateStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SpecimenEstimateStore = Labs.newMemorySpecimenEstimateStore()
        let item = Labs.newSpecimenEstimate("code-983", name: "name-130")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
