@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryModalitySummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ModalitySummaryStore = Imaging.newMemoryModalitySummaryStore()
        let item = Imaging.newModalitySummary("code-893", label: "label-54")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
