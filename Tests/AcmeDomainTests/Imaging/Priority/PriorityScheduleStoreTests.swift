@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryPriorityScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.PriorityScheduleStore = Imaging.newMemoryPriorityScheduleStore()
        let item = Imaging.newPrioritySchedule("code-913", label: "label-712")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
