@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryStudySummaryStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.StudySummaryStore = Imaging.newMemoryStudySummaryStore()
        let item = Imaging.newStudySummary("code-949", title: "title-898")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
