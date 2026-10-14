@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryReferenceRangeVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.ReferenceRangeVarianceStore = Labs.newMemoryReferenceRangeVarianceStore()
        let item = Labs.newReferenceRangeVariance("code-120", title: "title-36")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
