@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryStrictSpecimenVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.StrictSpecimenVarianceStore = Labs.newMemoryStrictSpecimenVarianceStore()
        let item = Labs.newStrictSpecimenVariance("code-86", title: "title-765")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
