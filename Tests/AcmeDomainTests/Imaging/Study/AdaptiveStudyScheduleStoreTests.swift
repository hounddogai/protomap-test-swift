@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryAdaptiveStudyScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.AdaptiveStudyScheduleStore = Imaging.newMemoryAdaptiveStudyScheduleStore()
        let item = Imaging.newAdaptiveStudySchedule("code-283", name: "name-222")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
