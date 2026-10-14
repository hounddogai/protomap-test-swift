@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryRollingWorklistScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.RollingWorklistScheduleStore = Imaging.newMemoryRollingWorklistScheduleStore()
        let item = Imaging.newRollingWorklistSchedule("code-487", label: "label-743")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
