@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryFallbackReferenceRangeVarianceStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.FallbackReferenceRangeVarianceStore = Labs.newMemoryFallbackReferenceRangeVarianceStore()
        let item = Labs.newFallbackReferenceRangeVariance("code-399", label: "label-960")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
