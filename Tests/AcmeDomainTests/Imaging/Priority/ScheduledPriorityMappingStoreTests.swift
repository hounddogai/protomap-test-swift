@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledPriorityMappingStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledPriorityMappingStore = Imaging.newMemoryScheduledPriorityMappingStore()
        let item = Imaging.newScheduledPriorityMapping("code-177", title: "title-1")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
