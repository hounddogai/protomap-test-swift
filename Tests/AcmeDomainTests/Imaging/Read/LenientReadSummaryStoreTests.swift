@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryLenientReadSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.LenientReadSummaryStore = Imaging.newMemoryLenientReadSummaryStore()
        let item = Imaging.newLenientReadSummary("code-186", label: "label-614")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
