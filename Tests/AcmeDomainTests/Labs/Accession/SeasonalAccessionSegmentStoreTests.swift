@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemorySeasonalAccessionSegmentStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.SeasonalAccessionSegmentStore = Labs.newMemorySeasonalAccessionSegmentStore()
        let item = Labs.newSeasonalAccessionSegment("code-52", label: "label-905")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
