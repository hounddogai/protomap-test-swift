@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingMemoryReadScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Imaging.ReadScheduleStore = Imaging.newMemoryReadScheduleStore()
        let item = Imaging.newReadSchedule("code-531", name: "name-72")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
