@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryAccessionSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.AccessionSummaryStore = Labs.newMemoryAccessionSummaryStore()
        let item = Labs.newAccessionSummary("code-232", label: "label-859")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
