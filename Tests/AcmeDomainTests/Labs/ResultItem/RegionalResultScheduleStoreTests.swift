@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsMemoryRegionalResultScheduleStoreTests {
    @Test func findsWhatItSaved() throws {
        let store: any Labs.RegionalResultScheduleStore = Labs.newMemoryRegionalResultScheduleStore()
        let item = Labs.newRegionalResultSchedule("code-377", name: "name-507")
        store.save(item)
        let found = try #require(store.find(item.code))
        #expect(found.code == item.code)
        #expect(store.list().count == 1)
    }
}
