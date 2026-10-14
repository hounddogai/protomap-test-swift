@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryTieredStudySummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.TieredStudySummaryStore = Imaging.newMemoryTieredStudySummaryStore()
        let item = Imaging.newTieredStudySummary("code-829", name: "name-410")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
