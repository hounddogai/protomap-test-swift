@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryWeightedCourierExceptionStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.WeightedCourierExceptionStore = Labs.newMemoryWeightedCourierExceptionStore()
        let item = Labs.newWeightedCourierException("code-118", label: "label-277")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
