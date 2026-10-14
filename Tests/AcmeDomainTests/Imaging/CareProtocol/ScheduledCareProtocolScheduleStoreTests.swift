@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryScheduledCareProtocolScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ScheduledCareProtocolScheduleStore = Imaging.newMemoryScheduledCareProtocolScheduleStore()
        let item = Imaging.newScheduledCareProtocolSchedule("code-270", name: "name-786")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
