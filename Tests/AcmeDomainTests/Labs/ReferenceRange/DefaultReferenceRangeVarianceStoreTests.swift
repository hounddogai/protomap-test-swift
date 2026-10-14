@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryDefaultReferenceRangeVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.DefaultReferenceRangeVarianceStore = Labs.newMemoryDefaultReferenceRangeVarianceStore()
        let item = Labs.newDefaultReferenceRangeVariance("code-955", title: "title-372")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
