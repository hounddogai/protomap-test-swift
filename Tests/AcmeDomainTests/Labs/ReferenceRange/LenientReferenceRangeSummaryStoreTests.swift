@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryLenientReferenceRangeSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.LenientReferenceRangeSummaryStore = Labs.newMemoryLenientReferenceRangeSummaryStore()
        let item = Labs.newLenientReferenceRangeSummary("code-243", label: "label-662")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
