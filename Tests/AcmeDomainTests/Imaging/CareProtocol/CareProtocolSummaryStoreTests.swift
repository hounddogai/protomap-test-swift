@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryCareProtocolSummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.CareProtocolSummaryStore = Imaging.newMemoryCareProtocolSummaryStore()
        let item = Imaging.newCareProtocolSummary("code-652", label: "label-362")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
